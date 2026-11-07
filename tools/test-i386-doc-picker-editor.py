#!/usr/bin/env python3
"""Exercise physical F4/Shift-F4 from DocEd through real picker selection and cancellation."""
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
    fixture=ROOT/'tests/guest/i386-doc-picker-keys/Contract.HC'
    filemgr=ROOT/'Adam/ABlkDev/FileMgr.HC'
    original_filemgr=subprocess.check_output(['git','show','c26482bb6ad3f80106d28504ec5db3c6a360732c:Adam/ABlkDev/FileMgr.HC'],cwd=ROOT)
    if filemgr.read_bytes()!=original_filemgr:raise ValueError('FileMgr differs from pinned original')
    paths=[Path(__file__).resolve(),fixture,filemgr,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    libraries=['Adam/AutoComplete/MakeAC.HC','Adam/AutoComplete/ACFill.HC','Adam/AutoComplete/ACTask.HC','Adam/AutoComplete/ACInit.HC','Adam/TaskSettings.HC','Adam/TaskSettingsCore.HC'] if args.disk else []
    paths += [ROOT/name for name in libraries]
    prelude=ROOT/'tests/guest/i386-doc-picker-editor/Prelude.HC';paths.append(prelude)
    if fixture.read_bytes().count(b'DocPutKey(')!=2:raise ValueError('Unexpected fixture call sites')
    source=prelude.read_bytes()+fixture.read_bytes().replace(b'DocPutKey(',b'PKPhysicalKey(')
    if args.disk:paths.append(args.disk.resolve())
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='F4/Shift-F4 public dispatch: six metadata/modifier cases, file/directory selection and cancellation, insertion at a middle cursor, incoming lock restoration, unlocked caller during real focused FileMgr popup and exact serialized bytes. Physical F4/Shift-F4 events run inside DocEd(DOF_DONT_HOME). The prelude only replaces the fixture call with a real editor session; metadata still calls the public API directly. No heap, visual or default-editor qualification.');g=None
    (out/'fixture.HC').write_bytes(source);(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        additions={'/Probe/PickerKeys.HC':source,'/Probe/PickFileScope/Nested/Marker.TXT':b'picker fixture\n','/Probe/PickFileScope/Alpha.TXT':b'alpha\n'}
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
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+source+b'\nPKCheck("T:/Probe/PickFileScope");\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(args.disk))
        drive='C' if args.disk else 'T';root=drive+':/Probe/PickFileScope'
        if args.disk:
            g.wait('DONE native kernel startup\n')
            report['library_commands']=['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);'] if args.disk else []
            for command in report['library_commands']:g.command(command)
            g.command('#include "C:/Adam/ABlkDev/FileMgr.HC"');g.command('#include "C:/Probe/PickerKeys.HC"');g.type('PKCheck("'+root+'");');g.press('ret')
        for i,count in enumerate([3,2,3,2,3]):
            stage=0;armed=False;closed=False;deadline=time.monotonic()+300
            while True:
                text=g.collect()
                if f'PICKER KEY RETURN {i}\n' in text:break
                if not armed and f'PICKER KEY ARMED {i}\n' in text:
                    if i in (1,3):g.key('shift',True)
                    g.press('f4')
                    if i in (1,3):g.key('shift',False)
                    armed=True
                if not closed and f'PICKER KEY CLOSED {i}\n' in text:
                    g.press('esc');closed=True
                if stage<count and f'PICKER KEY READY {i} {stage}\n' in text:
                    g.screenshot(f'picker-{i}-{stage}')
                    if stage<count-1:g.press('down')
                    else:
                        if i in (2,3):g.key('shift',True)
                        g.press('esc')
                        if i in (2,3):g.key('shift',False)
                    stage+=1
                if g.p.poll() is not None or time.monotonic()>deadline:raise TimeoutError('Picker did not return: '+str(i))
                time.sleep(.1)
        g.wait('PICKER KEY DONE\n')
        expected={'picker-key-metadata.bin':struct.pack('<6q',*([15]*6)),
                  'picker-key-masks.bin':struct.pack('<5q',*([127]*5))}
        for i,path in enumerate([root+'/Alpha.TXT',root+'/Nested','','',root+'/Alpha.TXT']):
            expected[f'picker-key-{i}.bin']=('Before'+path+'After').encode()
        mismatches={}
        for n,b in expected.items():
            actual=(g.out/n).read_bytes();(out/n).write_bytes(actual)
            if actual!=b:mismatches[n]=dict(actual_hex=actual.hex(),expected_hex=b.hex())
        report['metadata']=list(struct.unpack('<6q',(out/'picker-key-metadata.bin').read_bytes()))
        report['masks']=list(struct.unpack('<5q',(out/'picker-key-masks.bin').read_bytes()))
        report['mismatches']=mismatches
        if args.disk:g.command('6*7;');report['arithmetic_pixels']=g.result_pixels()
        g.close();g=None
        if args.disk:
            after=pack['snapshot'](image.read_bytes())[1]
            verify_picker_files(before,after,additions)
            report['preserved_files']=len(before);report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        if mismatches:raise ValueError('Picker key dispatch differs: '+repr(mismatches))
        report.update(result='pass',capture_sha256={n:hashlib.sha256(b).hexdigest() for n,b in expected.items()})
    except BaseException as exc:report.update(result='fail',error=type(exc).__name__+': '+str(exc));raise
    finally:
        if g:
            try:g.close()
            except Exception as exc:report.update(result='fail',close_error=str(exc))
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
