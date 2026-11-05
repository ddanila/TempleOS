#!/usr/bin/env python3
"""Observe the unchanged bundled registry demo on the pinned original OS."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import shutil
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-registry-demo-reference'
    oracle=ROOT/'tools/guest/i386-kernel/StartupRegistryOracle.HC'
    reference=ROOT/'tools/test-i386-timeclock-reference.py'
    demo=ROOT/'Demo/RegistryDemo.HC'
    paths=[Path(__file__).resolve(),fixture/'Once.HC',oracle,reference,demo,
           ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',ROOT/'tools/i386-kernel-input.py',ROOT/'Kernel/FontStd.HC']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths};report=dict(result='fail',input_sha256=pins,
        scope='Actual unchanged RegistryDemo first launch from fresh defaults: printed score/value, increment, sampled time and persisted registry document; not a second boot or native qualification')
    try:
        ref=runpy.run_path(str(reference));overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=ref['restore_reference'](overlay)
        if sha(overlay/'Demo/RegistryDemo.HC')!=sha(demo):raise ValueError('Demo differs from pinned source')
        shutil.copyfile(oracle,overlay/'StartupRegistryOracle.HC')
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),
            '--overlay',str(fixture),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
        subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),
            '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        data=(out/'guest/demo-record.bin').read_bytes()
        if len(data)!=32:raise ValueError('Bad demo state record')
        value=struct.unpack_from('<q',data)[0];score,before,after=struct.unpack_from('<3d',data,8)
        if value!=1235 or not 0<=before<=score<=after:raise ValueError('Demo increment/time differs')
        state=(out/'guest/demo-registry.HC').read_bytes()
        match=re.search(rb'F64 best_score= *([0-9]+\.[0-9]{5});\n',state)
        if not match or abs(float(match[1])-score)>0.0000051 or b'1235;\n' not in state:
            raise ValueError('Persisted demo state differs from actual result')
        text=(out/'guest/demo-output.DD').read_bytes()
        if text.count(b'High Score:1.23000\n')!=1 or text.count(b'Val:1234\n')!=1:
            raise ValueError('Demo output differs from initial score/value')
        report.update(result='pass',value=value,score=score,time_bounds=[before,after],
            persisted_sha256=sha(out/'guest/demo-registry.HC'),output_sha256=sha(out/'guest/demo-output.DD'))
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Registry demo reference failed')


if __name__=='__main__':main()
