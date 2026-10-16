#!/usr/bin/env python3
"""Check original terminal welcome insertion and settings retained by DocClear."""
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
    fixture = ROOT/'tests/guest/i386-terminal-startup-reference'
    inputs = [Path(__file__).resolve(), Path(reference.__file__), fixture/'Once.HC',
              ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py']
    report = dict(result='running', reference_revision=reference.REFERENCE,
                  repair_revision=reference.REPAIRS,
                  reference_sha256=reference.restore_reference(overlay),
                  input_sha256={str(p):reference.sha(p) for p in inputs},
                  scope='Original DocTermNew, full welcome Type and DocClear; native startup and desktop task orchestration remain unqualified')
    try:
        iso = out/'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay',str(overlay),
                        '--overlay',str(fixture),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256'] = reference.sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),
                        '--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        observed = {name:(out/'guest'/name).read_bytes() for name in
                    ('terminal-empty.DD','terminal-welcome.DD','terminal-cleared.DD')}
        report['observed_hex'] = {name:data.hex() for name,data in observed.items()}
        if observed['terminal-empty.DD'] != b'':
            raise ValueError('Fresh original terminal serialization differs')
        if observed['terminal-cleared.DD'] != b'$WW+H,1$\x05':
            raise ValueError('Original welcome held word-wrap does not survive DocClear')
        welcome = observed['terminal-welcome.DD']
        if welcome != (overlay/'Doc/Start.DD').read_bytes()+b'\n\x05':
            raise ValueError('Full welcome document was not inserted')
        if 'DONE original terminal startup documents\n' not in (out/'guest/debug.log').read_text():
            raise ValueError('Original terminal initialization checks did not complete')
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
