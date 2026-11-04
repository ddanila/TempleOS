#!/usr/bin/env python3
"""Check public block globals alias the kernel-owned record."""
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
    fixture=ROOT/'tests/guest/i386-public-block-globals/Contract.HC'
    helper=ROOT/'tools/test-i386-timeclock-welcome.py'
    package=ROOT/'tools/package-i386-native-image.py'
    build=ROOT/'tools/build-i386-kernel.py'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths=[source,fixture,helper,package,build,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Public/kernel block-global identity, drive/device pointers and reversible counter aliasing; no block transfer executed')
    try:
        image=out/'working.img'
        runpy.run_path(str(package))['package'](source,image,additions={'/PublicBlockGlobals.HC':fixture.read_bytes()})
        runpy.run_path(str(helper))['guest'](image,out/'guest',['#include "C:/PublicBlockGlobals.HC"','6*7;'],64,True,accel=args.accel)
        delivered=runpy.run_path(str(build))['mutated_file_contents'](image,{'/PublicBlockGlobals.HC'})
        if delivered['/PublicBlockGlobals.HC']!=fixture.read_bytes():raise ValueError('Fixture changed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])
    print('PASS: public block globals fixture; inputs unchanged')

if __name__=='__main__':main()
