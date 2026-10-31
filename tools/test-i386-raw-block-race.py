#!/usr/bin/env python3
"""Check revalidation of a mounted drive after a queued block transfer."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-raw-block-race/Contract.HC'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[Path(__file__).resolve(),fixture]
    report=dict(result='running',mode='native',
                scope='Reject queued transfers after changes to drive size, offset, filesystem or read-only state; not full remap, public block API or concurrency qualification')
    inputs += [args.disk.resolve()]+[ROOT/n for n in ('tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/i386-kernel-input.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC')]
    report['input_sha256']={str(p):sha(p) for p in inputs}
    try:
        disk=out/'working.img'
        report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={'/RawBlocks.HC':fixture.read_bytes()})
        commands=['#include "C:/RawBlocks.HC"',"if(!RawBlockRace)throw('RawBlk',TRUE);",'6*7;']
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](disk,out/'guest',commands,args.ram_mib,True)
        files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,{'/RawBlocks.HC'})
        if files['/RawBlocks.HC']!=fixture.read_bytes():raise ValueError('Delivered fixture changed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==d for p,d in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
