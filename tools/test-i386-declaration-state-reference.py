#!/usr/bin/env python3
"""Capture original completed class/global declarations and redefinition."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True);args=parser.parse_args();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True);fixture=ROOT/'tests/guest/i386-declaration-state-reference'
    reference=ROOT/'tools/test-i386-timeclock-reference.py'
    paths=[Path(__file__).resolve(),fixture/'Once.HC',reference,ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins={str(p):sha(p) for p in paths}
    report=dict(result='fail',input_sha256=pins,
        scope='Actual original ExePutS class completion after error, class/global/function redefinition, caller binding and completed function before malformed successor; actual evaluations and saved diagnostics. Not native qualification.')
    try:
        ref=runpy.run_path(str(reference));overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=ref['restore_reference'](overlay)
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--overlay',str(fixture),
            '--output',str(out/'original.iso')],cwd=ROOT,check=True)
        subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),
            '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        if (out/'guest/debug.log').read_text().count('ADAM SERVER READY\n')!=1:raise ValueError('Missing real server readiness')
        data=(out/'guest/declarations.bin').read_bytes()
        if len(data)!=256:raise ValueError('Bad declaration record size')
        records=[list(struct.unpack_from('<4q',data,n*32)) for n in range(8)]
        expected=[[42,42,0,42],[0,42,8,42],[0,42,8,42],
            [0,42,1,97],[0,97,1,107],[0,107,1,1],[0,1,2,1],[0,1,99,1]]
        if records!=expected:raise ValueError('Original declaration state differs')
        for n in range(8):
            text=(out/f'guest/state-{n}.DD').read_bytes()
            if n in (1,3):
                if b'Undefined identifier' not in text:raise ValueError('Missing actual type diagnostic')
            elif n==7:
                if b'Invalid lval' not in text or b'Compiler Parse Error' not in text:
                    raise ValueError('Missing actual malformed-function diagnostics')
            elif text:raise ValueError('Unexpected execution output')
        report.update(result='pass',records=records)
    except Exception as exc:
        report['error']=str(exc);raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Declaration state reference failed')


if __name__=='__main__':main()
