#!/usr/bin/env python3
"""Capture original Refresh sync, pump, frame waits, force and task/document state."""
import argparse
import json
from pathlib import Path
import runpy
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    overlay = out/'reference-overlay'
    overlay.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-refresh-reference'
    sha = REFERENCE['sha']
    sources = REFERENCE['restore_reference'](overlay)
    inputs = [Path(__file__).resolve(), fixture/'Once.HC',
              ROOT/'tools/test-i386-timeclock-reference.py',
              ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py']
    pins = {str(p):sha(p) for p in inputs}
    report = dict(result='running', reference_revision=REFERENCE['REFERENCE'],
                  repair_revision=REFERENCE['REPAIRS'], source_sha256=sources,
                  input_sha256=pins, expected=[7,7,15,15,15,15],
                  scope='Original Refresh: zero-count sync, pump-only request, one/two-frame waits, force wake from future deadline, idle and full-refresh state preservation on ordinary return; not interruption or whole-desktop qualification')
    try:
        iso = out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),
                        '--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256'] = sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),
                        '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        data = (out/'guest/refresh.bin').read_bytes()
        report['observed'] = list(struct.unpack('<6q',data))
        if data != struct.pack('<6q',7,7,15,15,15,15):
            raise ValueError('Original Refresh differs from expected wait/state modes')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p))==digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Reference fixture inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':
    main()
