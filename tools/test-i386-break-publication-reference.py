#!/usr/bin/env python3
"""Observe original function publication after explicit break, throw and parse failure."""
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
    out.mkdir(parents=True);fixture=ROOT/'tests/guest/i386-break-publication-reference'
    reference=ROOT/'tools/test-i386-timeclock-reference.py'
    paths=[Path(__file__).resolve(),fixture/'Once.HC',reference,ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins={str(p):sha(p) for p in paths}
    report=dict(result='fail',input_sha256=pins,
        scope='Original ExePutS with default and CCF_CMD_LINE flags, function declarations followed by Break, runtime throw, parse error or pending flag; actual hash lookup and direct call after unwind. Synthetic pending flag cleared only after state capture. Not native or physical Ctrl-Alt-C qualification.')
    try:
        ref=runpy.run_path(str(reference));overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=ref['restore_reference'](overlay)
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--overlay',str(fixture),
            '--output',str(out/'original.iso')],cwd=ROOT,check=True)
        subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),
            '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        if (out/'guest/debug.log').read_text().count('ADAM SERVER READY\n')!=1:raise ValueError('Missing real server readiness')
        data=(out/'guest/publication.bin').read_bytes()
        if len(data)!=576:raise ValueError('Bad publication record size')
        records=[list(struct.unpack_from('<9q',data,n*72)) for n in range(8)]
        expected=[[0,0,41,10,1,0,1,99,41],
            [0,int.from_bytes(b'Delib','little'),41,10,1,0,1,99,41],
            [0,0,41,10,1,0,1,99,41],[2048,0,2048,9,1,2048,1,99,2048]]*2
        if records!=expected:raise ValueError('Original completed function publication differs')
        for n in range(8):
            text=(out/f'guest/output-{n}.DD').read_bytes()
            if n%4==2:
                if b'Undefined identifier' not in text or b'after_break' not in text:
                    raise ValueError('Missing actual parse diagnostic')
            elif text:raise ValueError('Unexpected automatic or diagnostic output')
        report.update(result='pass',records=records,compiler_flags=[0,1])
    except Exception as exc:
        report['error']=str(exc);raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Original publication reference failed')


if __name__=='__main__':main()
