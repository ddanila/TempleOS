#!/usr/bin/env python3
"""Compare real original key-map output before and after fixed-width slots."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-keymap-family-original/Once.HC'
    inputs=[Path(__file__).resolve(),fixture]+[ROOT/n for n in ('Adam/Training.HC','Adam/KeyMapSortCore.HC','tools/test-i386-timeclock-reference.py','tools/build-iso.py','tools/guest-run.py')]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    report=dict(result='running',input_sha256={str(p):sha(p) for p in inputs},scope='Original live key-description collection, sorting and serialized output for normal/shift family; not native execution, other modifiers or interactive key-map UI')
    try:
        ref=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'));outputs=[]
        for mode in ('pinned','shared'):
            overlay=out/(mode+'-overlay');overlay.mkdir();restored=ref['restore_reference'](overlay)
            if mode=='pinned':report['reference_sha256']=restored
            else:
                for name in ('Adam/Training.HC','Adam/KeyMapSortCore.HC'):
                    target=overlay/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes((ROOT/name).read_bytes())
            (overlay/'Once.HC').write_bytes(fixture.read_bytes());iso=out/(mode+'.iso')
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/mode),'--qmp-stdio','--timeout','180'],cwd=ROOT,check=True)
            data=(out/mode/'keymap.bin').read_bytes();outputs.append(data)
            if len(data)<128:raise ValueError('Key-map output unexpectedly small')
        report['lengths']=[len(data) for data in outputs];report['sha256']=[hashlib.sha256(data).hexdigest() for data in outputs]
        if outputs[0]!=outputs[1]:raise ValueError('Shared key-map output differs from pinned original')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
