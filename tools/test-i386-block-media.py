#!/usr/bin/env python3
"""Check retained native media, allocator handoff and block streams."""
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
    fixture=ROOT/'tests/guest/i386-block-media/Contract.HC'
    helper=ROOT/'tools/test-i386-timeclock-welcome.py'
    package=ROOT/'tools/package-i386-native-image.py'
    build=ROOT/'tools/build-i386-kernel.py'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths=[source,fixture,helper,package,build,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Original/retained-provider allocation handoff, root/non-root growth and parent links, native RAM and file-backed image initialization, blocks, bounds/read-only/nested locks, FAT32 allocation and physically fragmented CFile block streams; no full FAT32 path or ATAPI qualification')
    try:
        image=out/'working.img'
        runpy.run_path(str(package))['package'](source,image,additions={'/BlockMedia.HC':fixture.read_bytes()})
        runpy.run_path(str(helper))['guest'](image,out/'guest',['#include "C:/BlockMedia.HC"','BlockMediaContract;','6*7;'],64,True,accel=args.accel)
        delivered=runpy.run_path(str(build))['mutated_file_contents'](image,{'/BlockMedia.HC'})
        if delivered['/BlockMedia.HC']!=fixture.read_bytes():raise ValueError('Fixture changed')
        report['filesystem_integrity']=runpy.run_path(str(build))['verify_mutated_volume'](image)
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])
    print('PASS: retained block/media fixture; inputs unchanged')

if __name__=='__main__':main()
