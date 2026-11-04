#!/usr/bin/env python3
"""Capture fresh RegInit defaults from the pinned original OS."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess

ROOT=Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-startup-registry-reference'
    oracle=ROOT/'tools/guest/i386-kernel/StartupRegistryOracle.HC'
    golden=ROOT/'tests/i386/startup-registry-reference.json'
    reference=ROOT/'tools/test-i386-timeclock-reference.py'
    paths=[Path(__file__).resolve(),fixture/'Once.HC',oracle,golden,reference,
           ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths};report=dict(result='fail',input_sha256=pins,
        scope='Pinned original RegInit in a fresh writable document; exact default DolDoc and original CompressBuf archive')
    try:
        ref=runpy.run_path(str(reference));expected=json.loads(golden.read_text())
        if (expected['reference_revision'],expected['repair_revision'])!=(ref['REFERENCE'],ref['REPAIRS']):
            raise ValueError('Registry oracle revision mismatch')
        overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=ref['restore_reference'](overlay)
        shutil.copyfile(oracle,overlay/'StartupRegistryOracle.HC')
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),
            '--overlay',str(fixture),'--output',str(out/'original.iso')],cwd=ROOT,check=True)
        report['iso_sha256']=sha(out/'original.iso')
        subprocess.run(['python3','tools/guest-run.py',str(out/'original.iso'),'--out',str(out/'guest'),
            '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        for name,key in [('StartupRegistry.HC','logical_hex'),('StartupRegistry.HC.Z','archive_hex')]:
            p=out/'guest'/name
            if p.read_bytes()!=bytes.fromhex(expected[key]):raise ValueError('Original registry differs: '+name)
        report.update(result='pass',logical_sha256=sha(out/'guest/StartupRegistry.HC'),
                      archive_sha256=sha(out/'guest/StartupRegistry.HC.Z'))
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Registry reference failed')


if __name__=='__main__':main()
