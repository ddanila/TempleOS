#!/usr/bin/env python3
"""Verify original media bitmap allocation and chunked zeroing on private RAM."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[1]
def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-media-block-helpers-reference'
    manifest=ROOT/'build/rebuild-test/result.json';snapshot=json.loads(manifest.read_text())
    if snapshot.get('result')!='pass':raise ValueError('Qualified original rebuild required')
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths=[Path(__file__).resolve(),fixture/'Once.HC',manifest,ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
    for name,relative in [('Kernel.BIN','0000Boot/0000Kernel.BIN.C'),('Compiler.BIN','Compiler/Compiler.BIN')]:
        p=ROOT/'build/rebuild-test/overlay'/relative
        if sha(p)!=snapshot['generations'][-1][name]:raise ValueError('Rebuild binary mismatch')
        paths.append(p)
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Current original x64 2049-sector RAM zeroing, boundaries, zero count, FAT-cache replacement/reset and nested locks; no native block I/O implementation')
    try:
        iso=out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        log=(out/'guest/debug.log').read_text()
        if 'PASS private RAM media block helpers\n' not in log or 'DONE media block helpers\n' not in log:raise ValueError('Media contract did not finish')
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])
if __name__=='__main__':main()
