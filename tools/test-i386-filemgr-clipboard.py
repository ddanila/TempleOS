#!/usr/bin/env python3
"""Exercise FileMgr file/tree selection, clipboard copy and paste through hardware keys through hardware keyboard input."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--tree',action='store_true',help='Copy a collapsed tree with Ctrl-Insert/Shift-Insert')
    args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-filemgr-clipboard/Contract.HC'
    filemgr=ROOT/'Adam/ABlkDev/FileMgr.HC'
    original=subprocess.check_output(['git','show','c26482bb6ad3f80106d28504ec5db3c6a360732c:Adam/ABlkDev/FileMgr.HC'],cwd=ROOT)
    if filemgr.read_bytes()!=original:raise ValueError('FileMgr differs from pinned original')
    names=['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']
    paths=[Path(__file__).resolve(),fixture,filemgr,ROOT/'Kernel/FontStd.HC']+[ROOT/'tools'/n for n in names]
    libraries=['Adam/AutoComplete/MakeAC.HC','Adam/AutoComplete/ACFill.HC','Adam/AutoComplete/ACTask.HC','Adam/AutoComplete/ACInit.HC','Adam/TaskSettings.HC','Adam/TaskSettingsCore.HC']
    if args.disk:paths += [args.disk.resolve()]+[ROOT/n for n in libraries]
    out.mkdir();pins={str(p):sha(p) for p in paths};g=None
    report=dict(result='running',input_sha256=pins,tree=args.tree,scope='Actual unchanged FileMgr: keyboard selection, Ctrl-C/V file or Ctrl-Insert/Shift-Insert tree, exact clipboard entries, source/copied bytes, empty directories, clipboard reset and caller restoration; native serialized filesystem and reboot. Not complete clipboard or FileMgr qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
            _,before,before_dirs=pack['snapshot'](args.disk.read_bytes())
            if '/FMClip' in before_dirs:raise ValueError('Fixture directory already exists')
            if before['/Adam/ABlkDev/FileMgr.HC'][2]!=original:raise ValueError('Delivered FileMgr differs')
            for n in libraries:
                if before['/'+n][2]!=(ROOT/n).read_bytes():raise ValueError('Delivered library differs: '+n)
            report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/FileMgrClipboard.HC':fixture.read_bytes()})
        else:
            overlay=out/'overlay';overlay.mkdir()
            report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+(('\nFCPCheck("B:/FMClip",'+str(int(args.tree))+');\n').encode()))
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n')
            for c in ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Adam/ABlkDev/FileMgr.HC"','#include "C:/Probe/FileMgrClipboard.HC"']:g.command(c)
            g.type('FCPCheck("C:/FMClip",'+str(int(args.tree))+');');g.press('ret')
        def chord(mod,key):
            g.key(mod,True);g.press(key);g.key(mod,False)
        for phase in range(5 if args.tree else 8):
            g.wait(f'FILEMGR CLIP READY {phase}\n',timeout=300);g.screenshot(f'phase-{phase}')
            if args.tree:
                if phase==0:g.press('down')
                elif phase==1:chord('shift','down')
                elif phase==2:chord('ctrl','insert')
                elif phase==3:chord('shift','insert')
                else:g.press('esc')
            else:
                if phase in (0,1):g.press('down')
                elif phase==2:chord('shift','down')
                elif phase==3:chord('ctrl','c')
                elif phase in (4,5):g.press('up')
                elif phase==6:chord('ctrl','v')
                else:g.press('esc')
        g.wait('FILEMGR CLIP DONE\n')
        expected_payload=bytes([0,1,127,128,254,255]) if args.tree else b'alpha\n'
        expected={'clip-rows.bin':struct.pack('<13q',*([1]*13)),
                  'clip-mask.bin':struct.pack('<q',15 if args.tree else 1),
                  'source.bin':expected_payload,'copied.bin':expected_payload}
        for name,want in expected.items():
            data=(g.out/name).read_bytes();(out/name).write_bytes(data)
            if data!=want:raise ValueError(name+' differs: '+repr(data))
        report['rows']=list(struct.unpack('<13q',(out/'clip-rows.bin').read_bytes()))
        report['clipboard_mask']=15 if args.tree else 1
        if args.disk:g.command('6*7;');report['arithmetic_pixels']=g.result_pixels()
        g.close();g=None
        if args.disk:
            _,after,after_dirs=pack['snapshot'](image.read_bytes())
            if any(after.get(n)!=v for n,v in before.items()):raise ValueError('Preexisting file changed')
            source_path='/FMClip/Alpha.TXT';copy_path='/FMClip/Dest/Alpha.TXT'
            wanted_dirs={'/FMClip','/FMClip/Dest'}
            if args.tree:
                source_path='/FMClip/Alpha/Nested/Payload.BIN';copy_path='/FMClip/Dest/Alpha/Nested/Payload.BIN'
                wanted_dirs|={'/FMClip/Alpha','/FMClip/Alpha/Empty','/FMClip/Alpha/Nested',
                              '/FMClip/Dest/Alpha','/FMClip/Dest/Alpha/Empty','/FMClip/Dest/Alpha/Nested'}
            expected_files={'/Probe/FileMgrClipboard.HC':fixture.read_bytes(),'/FMClip/Keep.TXT':b'keep\n',
                            source_path:expected_payload,copy_path:expected_payload}
            if {n:v[2] for n,v in after.items() if n not in before}!=expected_files:raise ValueError('Unexpected file bytes/paths')
            if not set(before_dirs)<=set(after_dirs):raise ValueError('Preexisting directory removed')
            if any(after_dirs[n][0]!=v[0] for n,v in before_dirs.items()):raise ValueError('Preexisting directory attributes changed')
            added_dirs=set(after_dirs)-set(before_dirs)
            if added_dirs-{'/Probe'}!=wanted_dirs:raise ValueError('Unexpected directories: '+repr(added_dirs))
            report['created_directories']=sorted(added_dirs)
            report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
            g=Guest(image,out/'reboot',True);g.wait('DONE native kernel startup\n')
            g.command('Cd("C:/FMClip");')
            command='6*7*(FileFind("'+source_path.removeprefix('/FMClip/')+'")&&FileFind("'+copy_path.removeprefix('/FMClip/')+'")&&FileFind("Keep.TXT")'
            if args.tree:command+='&&IsDir("Dest/Alpha/Empty")'
            g.command(command+');')
            report['reboot_pixels']=g.result_pixels();g.close();g=None
        report['result']='pass'
    except BaseException as exc:
        report.update(result='fail',error=type(exc).__name__+': '+str(exc));raise
    finally:
        if g:
            try:g.close()
            except Exception as exc:report.update(result='fail',cleanup_error=str(exc))
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
