#!/usr/bin/env python3
"""Produce an original-system archive of the pinned autocomplete word list."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    overlay=out/'overlay';overlay.mkdir(parents=True)
    ref=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
    fixture=ROOT/'tests/guest/i386-autocomplete-archive';source=ROOT/'Adam/AutoComplete/ACWords.DATA';inventory=ROOT/'docs/i386-compatibility-inventory.json'
    paths=[Path(__file__).resolve(),fixture/'Once.HC',source,inventory,ROOT/'tools/test-i386-timeclock-reference.py',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Original CompressBuf archive and ExpandBuf roundtrip of pinned autocomplete word list; not native dictionary or autocomplete qualification')
    try:
        expected=next(e['reference_sha256'] for e in json.loads(inventory.read_text())['entries'] if e['path']=='Adam/AutoComplete/ACWords.DATA')
        if sha(source)!=expected:raise ValueError('Word list differs from pinned original')
        report['reference_sha256']=ref['restore_reference'](overlay)
        if sha(overlay/'Adam/AutoComplete/ACWords.DATA')!=expected:raise ValueError('Original overlay word list mismatch')
        iso=out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256']=sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','180'],cwd=ROOT,check=True)
        archive=out/'guest/ACWords.DATA.Z';payload=archive.read_bytes()
        compressed,expanded=struct.unpack_from('<qq',payload)
        if compressed!=len(payload) or expanded!=source.stat().st_size:raise ValueError('Archive header mismatch')
        report.update(result='pass',archive_sha256=sha(archive),archive_bytes=len(payload),expanded_bytes=expanded)
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
