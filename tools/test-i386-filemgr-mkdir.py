#!/usr/bin/env python3
"""Exercise FileMgr directory creation and cancellation through hardware keyboard input."""
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
    args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-filemgr-mkdir/Contract.HC'
    filemgr=ROOT/'Adam/ABlkDev/FileMgr.HC'
    original=subprocess.check_output(['git','show','c26482bb6ad3f80106d28504ec5db3c6a360732c:Adam/ABlkDev/FileMgr.HC'],cwd=ROOT)
    if filemgr.read_bytes()!=original:raise ValueError('FileMgr differs from pinned original')
    names=['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']
    paths=[Path(__file__).resolve(),fixture,filemgr,ROOT/'Kernel/FontStd.HC']+[ROOT/'tools'/n for n in names]
    libraries=['Adam/AutoComplete/MakeAC.HC','Adam/AutoComplete/ACFill.HC','Adam/AutoComplete/ACTask.HC','Adam/AutoComplete/ACInit.HC','Adam/TaskSettings.HC','Adam/TaskSettingsCore.HC']
    if args.disk:paths += [args.disk.resolve()]+[ROOT/n for n in libraries]
    out.mkdir();pins={str(p):sha(p) for p in paths};g=None
    report=dict(result='running',input_sha256=pins,scope='Actual unchanged FileMgr: create Made via d/form/Escape, cancel Cancelled via Shift-Escape, exit, caller restoration and survivor bytes. Native additionally checks persisted paths and reboot. Not complete FileMgr qualification.')
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
            _,before,before_dirs=pack['snapshot'](args.disk.read_bytes())
            if '/FMWork' in before_dirs:raise ValueError('Fixture directory already exists')
            if before['/Adam/ABlkDev/FileMgr.HC'][2]!=original:raise ValueError('Delivered FileMgr differs')
            for n in libraries:
                if before['/'+n][2]!=(ROOT/n).read_bytes():raise ValueError('Delivered library differs: '+n)
            report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/FileMgrWork.HC':fixture.read_bytes()})
        else:
            overlay=out/'overlay';overlay.mkdir()
            report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\nFMWCheck("B:/FMWork");\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest']
        g=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n')
            for c in ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);','#include "C:/Adam/ABlkDev/FileMgr.HC"','#include "C:/Probe/FileMgrWork.HC"']:g.command(c)
            g.type('FMWCheck("C:/FMWork");');g.press('ret')
        for phase in range(5):
            g.wait(f'FILEMGR READY {phase}\n');g.screenshot(f'phase-{phase}')
            if phase in (0,2):g.type('d')
            elif phase in (1,3):
                g.type('Made' if phase==1 else 'Cancelled')
                g.screenshot(f'typed-{phase}')
                if phase==3:g.key('shift',True)
                g.press('esc')
                if phase==3:g.key('shift',False)
            else:g.press('esc')
        g.wait('FILEMGR MKDIR DONE\n')
        data=(g.out/'mkdir-rows.bin').read_bytes();(out/'mkdir-rows.bin').write_bytes(data)
        report['rows']=list(struct.unpack('<9q',data))
        if data!=struct.pack('<9q',*([1]*9)):raise ValueError('FileMgr state differs: '+repr(report['rows']))
        if args.disk:g.command('6*7;');report['arithmetic_pixels']=g.result_pixels()
        g.close();g=None
        if args.disk:
            _,after,after_dirs=pack['snapshot'](image.read_bytes())
            if any(after.get(n)!=v for n,v in before.items()):raise ValueError('Preexisting file changed')
            if {n:v[2] for n,v in after.items() if n not in before}!={'/Probe/FileMgrWork.HC':fixture.read_bytes(),'/FMWork/Keep.TXT':b'keep\n'}:raise ValueError('Unexpected file additions')
            added_dirs=set(after_dirs)-set(before_dirs)
            if added_dirs-{'/Probe'}!={'/FMWork','/FMWork/Made'}:raise ValueError('Unexpected directories: '+repr(added_dirs))
            report['created_directories']=sorted(added_dirs)
            report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
            g=Guest(image,out/'reboot',True);g.wait('DONE native kernel startup\n')
            g.command('6*7*(IsDir("C:/FMWork/Made")&&!IsDir("C:/FMWork/Cancelled"));')
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
