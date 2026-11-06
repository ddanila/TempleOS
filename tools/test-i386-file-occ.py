#!/usr/bin/env python3
"""Compare original FileOcc counting, search flags and silent-state restoration."""
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
    fixture=ROOT/'tests/guest/i386-file-occ/Contract.HC'
    assets={n:(fixture.parent/n).read_bytes() for n in ['A.TXT','B.TXT']}
    find=ROOT/'Adam/Opt/Utils/Find.HC'
    original=subprocess.check_output(['git','show','c26482bb6ad3f80106d28504ec5db3c6a360732c:Adam/Opt/Utils/Find.HC'],cwd=ROOT)
    if find.read_bytes()!=original:raise ValueError('Original Find source changed')
    paths=[find,*[fixture.parent/n for n in assets],Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if args.disk:paths.append(args.disk.resolve())
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='Complete original FileOcc/Find: case, label boundaries, overlap, no match, silent output, normal silent-state restoration and directory preservation. Not replacement, wizard, error cleanup or whole Psalmody qualification.');g=None
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
            before=pack['snapshot'](args.disk.read_bytes())[1]
            if before['/Adam/Opt/Utils/Find.HC'][2]!=original:raise ValueError('Delivered Find differs')
            report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/FileOcc.HC':fixture.read_bytes(),**{'/Probe/FindScope/'+n:v for n,v in assets.items()}})
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            dest=overlay/'Probe/FindScope';dest.mkdir(parents=True,exist_ok=True)
            for n,v in assets.items():(dest/n).write_bytes(v)
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture.read_bytes()+b'\nFileOccCheck("T:/Probe/FindScope");\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n');g.command('#include "C:/Adam/Opt/Utils/Find.HC"');g.command('#include "C:/Probe/FileOcc.HC"');g.command('FileOccCheck("C:/Probe/FindScope");')
        g.wait('FILE OCC DONE\n')
        expected={'counts.bin':struct.pack('<10q',5,9,7,3,8,6,3,0,5,4095)}
        for name,want in expected.items():
            actual=(g.out/name).read_bytes();(out/name).write_bytes(actual)
            if actual!=want:raise ValueError(name+' differs from independent byte oracle')
        if args.disk:g.command('6*7;');g.result_pixels()
        g.close();g=None
        if args.disk:
            after=pack['snapshot'](image.read_bytes())[1]
            changed={n for n in set(before)|set(after) if before.get(n)!=after.get(n)}
            if changed!={'/Probe/FileOcc.HC',*["/Probe/FindScope/"+n for n in assets]}:raise ValueError('Unexpected file changes')
            report['preserved_files']=len(before)
            report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report.update(result='pass',mask=4095,
                      table_sha256={n:hashlib.sha256(v).hexdigest() for n,v in expected.items()})
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
