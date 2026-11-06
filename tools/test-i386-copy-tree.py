#!/usr/bin/env python3
"""Compare original recursive CopyTree bytes, counts, empty directories and overlap rejection."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import struct

ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-copy-tree/Contract.HC'
    paths=[Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if args.disk:paths.append(args.disk.resolve())
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='Recursive CopyTree: nested binary/text and empty directories, exact returns, overlap rejection and caller directory; not all masks, faults, metadata or whole FileMgr qualification.');g=None
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
            before=pack['snapshot'](args.disk.read_bytes())[1]
            report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/CopyTree.HC':fixture.read_bytes()})
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\nCTCheck("B:/TreeProbe");\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n');g.command('#include "C:/Probe/CopyTree.HC"');g.command('CTCheck("C:/TreeProbe");')
        g.wait('COPY TREE DONE\n')
        expected={'counts.bin':struct.pack('<7q',5,0,0,1,0,1,1),
                  'source-alpha.bin':b'alpha\n','copied-alpha.bin':b'alpha\n',
                  'source-beta.bin':bytes([0,127,128,255]),'copied-beta.bin':bytes([0,127,128,255])}
        for name,want in expected.items():
            actual=(g.out/name).read_bytes();(out/name).write_bytes(actual)
            if actual!=want:raise ValueError(name+' differs from independent byte oracle')
        if args.disk:
            g.command('6*7;');g.result_pixels();g.close();g=None
            after=pack['snapshot'](image.read_bytes())[1]
            expected_files={'/Probe/CopyTree.HC':fixture.read_bytes(),
                            '/TreeProbe/Src/Alpha.TXT':b'alpha\n','/TreeProbe/Dst/Alpha.TXT':b'alpha\n',
                            '/TreeProbe/Src/Nested/Beta.BIN':bytes([0,127,128,255]),
                            '/TreeProbe/Dst/Nested/Beta.BIN':bytes([0,127,128,255])}
            if any(after.get(n)!=v for n,v in before.items()):raise ValueError('Preexisting file changed')
            added={n:v[2] for n,v in after.items() if n not in before}
            if added!=expected_files:raise ValueError('Unexpected created file bytes/paths')
            report['preserved_files']=len(before)
            report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report.update(result='pass',cases_checked=4,
                      table_sha256={n:hashlib.sha256(v).hexdigest() for n,v in expected.items()})
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
