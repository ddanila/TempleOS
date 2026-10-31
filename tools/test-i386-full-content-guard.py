#!/usr/bin/env python3
"""Check full-profile inventory and capacity rejection before disk writes."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    inventory = ROOT/'docs/i386-compatibility-inventory.json'
    inputs = [Path(__file__).resolve(), inventory, ROOT/'tools/build-i386-kernel.py']
    pins = {str(path):sha(path) for path in inputs}
    report = {'result':'running', 'input_sha256':pins,
              'scope':'Reject incomplete inventory and undersized full-profile disk without writes'}
    try:
        helper = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        package = helper['package_volume']
        with tempfile.TemporaryDirectory(dir=out) as tmp:
            root = Path(tmp)
            (root/'docs').mkdir()
            altered = json.loads(inventory.read_text())
            altered['entries'] = altered['entries'][:-1]
            (root/'docs/i386-compatibility-inventory.json').write_text(json.dumps(altered))
            package.__globals__['ROOT'] = root
            for size, expected in [(64, 'inventory does not match'), (16, 'requires a disk')]:
                disk = root/f'disk-{size}.img'
                with disk.open('wb') as stream:
                    stream.truncate(size*1024*1024)
                before = sha(disk)
                try:
                    package(disk, root/'unused', 'full')
                except ValueError as exc:
                    if expected not in str(exc):
                        raise
                else:
                    raise ValueError(f'Expected rejection for {size} MiB case')
                if sha(disk) != before:
                    raise ValueError('Rejected packaging modified the disk')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(path)==pins[str(path)] for path in inputs)
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
