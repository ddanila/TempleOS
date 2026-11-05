#!/usr/bin/env python3
"""Observe two unchanged registry-demo launches with a real document reload."""
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
    fixture=ROOT/'tests/guest/i386-registry-demo-repeat-reference'
    first=ROOT/'tests/guest/i386-registry-demo-reference/Once.HC'
    oracle=ROOT/'tools/guest/i386-kernel/StartupRegistryOracle.HC'
    reference=ROOT/'tools/test-i386-timeclock-reference.py'
    demo=ROOT/'Demo/RegistryDemo.HC'
    paths=[Path(__file__).resolve(),fixture/'Once.HC',first,oracle,reference,demo,
           ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',ROOT/'tools/i386-kernel-input.py',ROOT/'Kernel/FontStd.HC']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths};report=dict(result='fail',input_sha256=pins,
        scope='Actual unchanged RegistryDemo two launches with document reload: printed score/value, increment, sampled time and persisted registry document; not a machine reboot or native qualification')
    try:
        ref=runpy.run_path(str(reference));overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=ref['restore_reference'](overlay)
        if sha(overlay/'Demo/RegistryDemo.HC')!=sha(demo):raise ValueError('Demo differs from pinned source')
        shutil.copyfile(oracle,overlay/'StartupRegistryOracle.HC')
        #The shared first-launch fixture must not terminate host capture early.
        (overlay/'FirstRegistryDemo.HC').write_text(first.read_text().replace(
            'DONE original registry demo', 'PASS original registry demo first launch'))
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
        repeat_data=(out/'guest/repeat-record.bin').read_bytes()
        if len(repeat_data)!=32:raise ValueError('Bad repeated demo record')
        repeat_value=struct.unpack_from('<q',repeat_data)[0]
        repeat_score,repeat_before,repeat_after=struct.unpack_from('<3d',repeat_data,8)
        if repeat_value!=1236 or not 0<=repeat_before<=repeat_score<=repeat_after:
            raise ValueError('Repeated demo increment/time differs')
        repeat_state=(out/'guest/repeat-registry.HC').read_bytes()
        repeat_match=re.search(rb'F64 best_score= *([0-9]+\.[0-9]{5});\n',repeat_state)
        if not repeat_match or abs(float(repeat_match[1])-repeat_score)>0.0000051 or b'1236;\n' not in repeat_state:
            raise ValueError('Repeated persisted demo state differs')
        repeat_text=(out/'guest/repeat-output.DD').read_bytes()
        expected=b'High Score:'+match[1]+b'\nVal:1235\n\x05'
        if repeat_text!=expected:raise ValueError('Second launch did not display persisted first-launch state')
        report.update(result='pass',value=value,score=score,time_bounds=[before,after],
            repeat_value=repeat_value,repeat_score=repeat_score,
            repeat_time_bounds=[repeat_before,repeat_after],
            persisted_sha256=sha(out/'guest/demo-registry.HC'),
            repeated_persisted_sha256=sha(out/'guest/repeat-registry.HC'),
            repeated_output_sha256=sha(out/'guest/repeat-output.DD'))
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Registry demo reference failed')


if __name__=='__main__':main()
