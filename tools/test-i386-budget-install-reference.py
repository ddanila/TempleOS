#!/usr/bin/env python3
"""Verify the unchanged original Budget installer with its compressed template."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
reference=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('archive',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    overlay=out/'reference-overlay';overlay.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-budget-install-reference'
    paths=[args.archive.resolve(),ROOT/'Apps/Budget/Accts.DD',Path(__file__).resolve(),ROOT/'tools/test-i386-timeclock-reference.py',fixture/'Once.HC',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    report=dict(result='running',reference_revision=reference['REFERENCE'],repair_revision=reference['REPAIRS'],reference_sha256=reference['restore_reference'](overlay),input_sha256={str(p):sha(p) for p in paths},scope='Pinned original Install.HC run twice, using the packaged compressed template; exact installed logical bytes; not application workflow qualification')
    try:
        (overlay/'Apps/Budget/Accts.DD.Z').write_bytes(args.archive.read_bytes())
        iso=out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256']=sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        data=(out/'guest/installed-accounts.DD').read_bytes()
        expected=(overlay/'Apps/Budget/Accts.DD').read_bytes()
        if data!=expected:raise ValueError('Installed template differs from original')
        report.update(result='pass',installed_sha256=hashlib.sha256(data).hexdigest())
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
