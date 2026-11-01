#!/usr/bin/env python3
"""Exercise the shared FAT chain-intersection body with a synthetic graph."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / 'tests/guest/i386-fat-chain-overlap/Contract.HC'
CORE = ROOT / 'Kernel/BlkDev/FATChainOverlapCore.HC'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    overlay = out / 'overlay'
    overlay.mkdir()
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    inputs = [Path(__file__).resolve(), FIXTURE, CORE] + [ROOT / n for n in
        ('tools/test-i386-timeclock-reference.py', 'tools/build-iso.py', 'tools/guest-run.py')]
    ref = runpy.run_path(str(ROOT / 'tools/test-i386-timeclock-reference.py'))
    report = {'result': 'running', 'scope': 'Synthetic chain intersections and cycle bounds; not disk mutation',
              'reference_sha256': ref['restore_reference'](overlay),
              'input_sha256': {str(p): sha(p) for p in inputs}}
    try:
        helper = CORE.read_text().replace('CDrv', 'FOTestDrive').replace('ClusNumNext', 'FONext').replace('FAT32ChainOverlap', 'FOOverlap')
        body = FIXTURE.read_text().replace('// INSERT HELPER', helper)
        (overlay / 'Once.HC').write_text(body)
        iso = out / 'original.iso'
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
        report['iso_sha256'] = sha(iso)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out', str(out / 'guest'), '--qmp-stdio', '--timeout', '120'], cwd=ROOT, check=True)
        if 'FAT OVERLAP MASK 2047\n' not in (out / 'guest/debug.log').read_text():
            raise ValueError('Synthetic FAT overlap contract failed')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p, digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Execution inputs changed')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
