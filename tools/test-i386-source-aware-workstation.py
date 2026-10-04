#!/usr/bin/env python3
"""Run the full workstation suite with an independent disk-based source-view oracle."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    out=args.out.resolve();out.mkdir(parents=True,exist_ok=True)
    candidate=out/'writable.img'
    if candidate==args.disk.resolve():parser.error('output overlaps source')
    original=args.disk.read_bytes();candidate.write_bytes(original)
    report=dict(result='fail',source_disk_sha256=hashlib.sha256(original).hexdigest())
    (out/'result.json').unlink(missing_ok=True)
    try:
        load=runpy.run_path(str(ROOT/'tools/i386-file-find-heap-observer.py'))['observed_input']
        runner=load(candidate,report,private=False)
        report.update(runner(candidate,out,snapshot=False,cpu='486,-fpu',qmp_stdio=True))
    except Exception as error:
        report['error']=str(error);raise
    finally:
        report['source_disk_unchanged']=args.disk.read_bytes()==original
        if not report['source_disk_unchanged']:report.update(result='fail',error='Source changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
