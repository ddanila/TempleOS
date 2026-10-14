#!/usr/bin/env python3
"""Capture original streaming DolDoc output before porting the public binding."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('reference', ROOT/'tools/test-i386-timeclock-reference.py')
reference = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reference)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    overlay = out/'reference-overlay'
    overlay.mkdir(parents=True)
    fixture = ROOT/'tests/guest/i386-doc-stream-reference'
    inputs = [Path(__file__).resolve(), Path(reference.__file__), fixture/'Once.HC',
              ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py']
    report = dict(result='running', reference_revision=reference.REFERENCE,
                  repair_revision=reference.REPAIRS,
                  reference_sha256=reference.restore_reference(overlay),
                  input_sha256={str(p):reference.sha(p) for p in inputs},
                  scope='Explicit-document streaming output: partial markup, completion, escaped dollar, plain-text bypass and middle insertion; not default console rendering or complete DocPrintPartial parity')
    expected = {'stream.bin':b'leftcash$right\0',
                'plain.bin':b'$RED$cash$$\0',
                'insert.bin':b'abXYcd\0'}
    try:
        iso = out/'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',str(overlay),
                        '--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256'] = reference.sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),
                        '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        observed = {name:(out/'guest'/name).read_bytes() for name in expected}
        report['observed_hex'] = {name:data.hex() for name,data in observed.items()}
        if observed != expected:
            raise ValueError('Original streaming output differs from explicit byte expectations')
        if 'PASS original document streaming\n' not in (out/'guest/debug.log').read_text():
            raise ValueError('Original streaming state checks did not complete')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        if any(reference.sha(Path(p)) != digest for p,digest in report['input_sha256'].items()):
            report.update(result='fail', error='Reference fixture or tools changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
