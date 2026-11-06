#!/usr/bin/env python3
"""Exercise the real directory chooser: default/explicit directory and cancel."""
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

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-pick-dir/Contract.HC'
    paths=[Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if args.disk:paths.append(args.disk.resolve())
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='Actual PopUpPickDir/FileMgr: default and explicit directory selection, Shift-Escape allocated empty result, caller documents/popup/directory restoration; not whole FileMgr qualification.');g=None
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        additions={'/Probe/PickDir.HC':fixture.read_bytes(),'/Probe/PickScope/Nested/Marker.TXT':b'picker fixture\n'}
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img';before=pack['snapshot'](args.disk.read_bytes())[1]
            report['packaging']=pack['package'](args.disk.resolve(),image,additions=additions)
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            for n,b in additions.items():
                p=overlay/n.lstrip('/');p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\nPDCheck("T:/Probe/PickScope");\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(args.disk))
        drive='C' if args.disk else 'T';root=drive+':/Probe/PickScope'
        if args.disk:
            g.wait('DONE native kernel startup\n');g.command('#include "C:/Probe/PickDir.HC"');g.type('PDCheck("'+root+'");');g.press('ret')
        for i in range(3):
            g.wait(f'PICK DIR READY {i}\n');time.sleep(1);g.screenshot(f'picker-{i}')
            if i==2:g.key('shift',True)
            g.press('esc')
            if i==2:g.key('shift',False)
            g.wait(f'PICK DIR RETURN {i}\n')
        g.wait('PICK DIR DONE\n')
        expected={'masks.bin':struct.pack('<3q',127,127,127),**{f'selected{i}.TXT':v.encode()+b'\0' for i,v in enumerate([root,root+'/Nested',''])}}
        for n,b in expected.items():
            actual=(g.out/n).read_bytes();(out/n).write_bytes(actual)
            if actual!=b:raise ValueError(n+' differs from independent oracle: '+repr(actual))
        if args.disk:g.command('6*7;');g.result_pixels()
        g.close();g=None
        if args.disk:
            after=pack['snapshot'](image.read_bytes())[1];changed={n for n in set(before)|set(after) if before.get(n)!=after.get(n)}
            if changed!=set(additions):raise ValueError('Unexpected file changes')
            report['preserved_files']=len(before);report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report.update(result='pass',capture_sha256={n:hashlib.sha256(b).hexdigest() for n,b in expected.items()})
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
