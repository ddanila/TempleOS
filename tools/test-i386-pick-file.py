#!/usr/bin/env python3
"""Exercise original file picker acceptance/cancellation and directory picker on a file."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def verify_picker_files(before,after,additions):
    if set(before)&set(additions):raise ValueError('Picker fixture already exists')
    if set(after)!=set(before)|set(additions):raise ValueError('Unexpected file paths')
    if any(after[n]!=v for n,v in before.items()):raise ValueError('Preexisting file changed')
    if any(after[n][2]!=data for n,data in additions.items()):raise ValueError('Picker fixture bytes changed')

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-pick-file/Contract.HC'
    filemgr=ROOT/'Adam/ABlkDev/FileMgr.HC'
    original_filemgr=subprocess.check_output(['git','show','c26482bb6ad3f80106d28504ec5db3c6a360732c:Adam/ABlkDev/FileMgr.HC'],cwd=ROOT)
    if filemgr.read_bytes()!=original_filemgr:raise ValueError('FileMgr differs from pinned original')
    paths=[Path(__file__).resolve(),fixture,filemgr,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    libraries=['Adam/AutoComplete/MakeAC.HC','Adam/AutoComplete/ACFill.HC','Adam/AutoComplete/ACTask.HC','Adam/AutoComplete/ACInit.HC','Adam/TaskSettings.HC','Adam/TaskSettingsCore.HC'] if args.disk else []
    paths += [ROOT/name for name in libraries]
    source=fixture.read_bytes()
    if args.disk:paths.append(args.disk.resolve())
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='Actual PopUpPickFile/FileMgr: default/explicit file selection, directory acceptance returns empty, cancellation; PopUpPickDir on a selected file returns parent. Exact allocated result and caller heap ownership, document/popup/cwd restoration; not complete FileMgr qualification.');g=None
    (out/'fixture.HC').write_bytes(source);(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        additions={'/Probe/PickFile.HC':source,'/Probe/PickFileScope/Nested/Marker.TXT':b'picker fixture\n','/Probe/PickFileScope/Alpha.TXT':b'alpha\n'}
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';before=pack['snapshot'](args.disk.read_bytes())[1]
            if before['/Adam/ABlkDev/FileMgr.HC'][2]!=original_filemgr:raise ValueError('Delivered FileMgr differs from original')
            for name in libraries:
                if before['/'+name][2]!=(ROOT/name).read_bytes():raise ValueError('Delivered library differs: '+name)
            report['packaging']=pack['package'](args.disk.resolve(),image,additions=additions)
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            for n,b in additions.items():
                p=overlay/n.lstrip('/');p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\nPFCheck("T:/Probe/PickFileScope");\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(args.disk))
        drive='C' if args.disk else 'T';root=drive+':/Probe/PickFileScope'
        if args.disk:
            g.wait('DONE native kernel startup\n')
            report['library_commands']=['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);'] if args.disk else []
            for command in report['library_commands']:g.command(command)
            g.command('#include "C:/Adam/ABlkDev/FileMgr.HC"');g.command('#include "C:/Probe/PickFile.HC"');g.type('PFCheck("'+root+'");');g.press('ret')
        for i,count in enumerate([3,2,1,3,3]):
            for stage in range(count):
                g.wait(f'PICK FILE READY {i} {stage}\n',timeout=300);g.screenshot(f'picker-{i}-{stage}')
                if stage<count-1:g.press('down')
                else:
                    if i==3:g.key('shift',True)
                    g.press('esc')
                    if i==3:g.key('shift',False)
            g.wait(f'PICK FILE RETURN {i}\n',timeout=300)
        g.wait('PICK FILE DONE\n')
        expected={'masks.bin':struct.pack('<5q',255,255,255,255,255),**{f'selected{i}.TXT':v.encode()+b'\0' for i,v in enumerate([root+'/Alpha.TXT',root+'/Nested/Marker.TXT','','',root])}}
        for n,b in expected.items():
            actual=(g.out/n).read_bytes();(out/n).write_bytes(actual)
            if actual!=b:raise ValueError(n+' differs from independent oracle: '+repr(actual))
        if args.disk:g.command('6*7;');report['arithmetic_pixels']=g.result_pixels()
        g.close();g=None
        if args.disk:
            after=pack['snapshot'](image.read_bytes())[1]
            verify_picker_files(before,after,additions)
            report['preserved_files']=len(before);report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report.update(result='pass',masks=[255]*5,capture_sha256={n:hashlib.sha256(b).hexdigest() for n,b in expected.items()})
    except BaseException as exc:report.update(result='fail',error=type(exc).__name__+': '+str(exc));raise
    finally:
        if g:
            try:g.close()
            except Exception as exc:report.update(result='fail',close_error=str(exc))
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
