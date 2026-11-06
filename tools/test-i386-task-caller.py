#!/usr/bin/env python3
"""Compare current and suspended task caller inspection with the original."""
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
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True);ap.add_argument('--shared-types',action='store_true',help='Diagnose native metadata after explicitly loading existing complete symbol types');args=ap.parse_args();out=args.out.resolve()
    if args.shared_types and not args.disk:ap.error('--shared-types is a native diagnostic option')
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-task-caller/Contract.HC'
    paths=[Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if args.disk:paths.append(args.disk.resolve())
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,explicit_shared_types=args.shared_types,scope='Current-task caller, suspended child saved/current equivalence, two real function frames, bounded exhaustion and child cleanup. Not debugger-stop contexts or whole Psalmody qualification.');g=None
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
            report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/TaskCaller.HC':fixture.read_bytes()})
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'TaskCaller.HC').write_bytes(fixture.read_bytes())
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n#include "::/TaskCaller.HC"\nTCCheck();\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n')
            if args.shared_types:g.command('#include "C:/Kernel/SymbolTypes.HH"')
            g.command('#include "C:/Probe/TaskCaller.HC"');g.command('TCCheck();')
        g.wait('TASK CALLER DONE\n')
        expected={'callers.bin':struct.pack('<7q',1,1,1,1,1,1,1)}
        for name,want in expected.items():
            actual=(g.out/name).read_bytes();(out/name).write_bytes(actual)
            if actual!=want:raise ValueError(name+' differs from independent byte oracle')
        if args.disk:g.command('6*7;');g.result_pixels()
        report.update(result='pass',cases_checked=1,
                      table_sha256={n:hashlib.sha256(v).hexdigest() for n,v in expected.items()})
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
