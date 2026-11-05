#!/usr/bin/env python3
"""Capture actual original task answers around pending and explicit breaks."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import re
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True);args=parser.parse_args();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True);fixture=ROOT/'tests/guest/i386-answer-break-reference'
    reference=ROOT/'tools/test-i386-timeclock-reference.py'
    paths=[Path(__file__).resolve(),fixture/'Once.HC',reference,ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins={str(p):sha(p) for p in paths}
    report=dict(result='fail',input_sha256=pins,
        scope='Original ExePutS/Break/pending flag/BreakUnlock and real CmdLinePmt; pending synthetic flags captured before restoration for safe inspection. Not physical break input or native qualification.')
    try:
        ref=runpy.run_path(str(reference));overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=ref['restore_reference'](overlay)
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--overlay',str(fixture),
            '--output',str(out/'original.iso')],cwd=ROOT,check=True)
        subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),
            '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        if (out/'guest/debug.log').read_text().count('ADAM SERVER READY\n')!=1:raise ValueError('Missing real server readiness')
        data=(out/'guest/break-state.bin').read_bytes()
        if len(data)!=288:raise ValueError('Bad break record size')
        records=[list(struct.unpack_from('<9q',data,n*72)) for n in range(4)]
        for n,row in enumerate(records):
            if row[7]:raise ValueError('Prompt did not consume pending answer')
            before=(out/f'guest/before-{n}.DD').read_bytes()
            if b'ans=' in before or b'ansf=' in before:raise ValueError('Answer printed before prompt')
        expected=[[0,0,41,10,1,0,41,0,0],[2048,0,2048,9,1,2048,2048,0,0],
            [2048,0,2048,9,1,2048,2048,0,0],[0,0,41,10,1,0,41,0,0]]
        if records!=expected:raise ValueError('Original break answer state differs')
        for n,row in enumerate(records):
            after=(out/f'guest/after-{n}.DD').read_bytes()
            if len(re.findall(rb'ans=0x[0-9A-F]+='+str(row[6]).encode()+rb'\n',after))!=1:
                raise ValueError('Prompt answer differs after break')
        report.update(result='pass',records=records)
    except Exception as exc:
        report['error']=str(exc);raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
