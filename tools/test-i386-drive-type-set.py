#!/usr/bin/env python3
"""Verify original partition type updates on a restored copied-image synthetic MBR."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--accel',choices=('tcg','kvm'),default='tcg')
    args=ap.parse_args();out=args.out.resolve();source=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-drive-type-set/Contract.HC'
    helper=ROOT/'tools/test-i386-timeclock-welcome.py'
    package=ROOT/'tools/package-i386-native-image.py'
    build=ROOT/'tools/build-i386-kernel.py'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths=[source,fixture,helper,package,build,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Original DrvTypeSet primary partition RedSea/FAT32 updates, invalid type rejection and preowned lock; temporary synthetic MBR on copied disk, original sector restored')
    try:
        image=out/'working.img'
        runpy.run_path(str(package))['package'](source,image,additions={'/DriveTypeSet.HC':fixture.read_bytes()})
        with image.open('rb') as f:header=f.read(512)
        runpy.run_path(str(helper))['guest'](image,out/'guest',['#include "C:/DriveTypeSet.HC"','6*7;'],64,True,accel=args.accel)
        with image.open('rb') as f:restored=f.read(512)
        if restored!=header:raise ValueError('Copied disk header was not restored')
        report['header_restored']=True
        delivered=runpy.run_path(str(build))['mutated_file_contents'](image,{'/DriveTypeSet.HC'})
        if delivered['/DriveTypeSet.HC']!=fixture.read_bytes():raise ValueError('Fixture changed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])
    print('PASS: drive type setter fixture; inputs unchanged')

if __name__=='__main__':main()
