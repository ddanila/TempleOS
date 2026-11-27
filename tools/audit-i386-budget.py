#!/usr/bin/env python3
"""Audit current Budget launcher, validation, recurrence and persistence captures."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
CHECKS = {
    'launch': {},
    'mouse': {'mask': 1023, 'reopen_mask': 63, 'cold_reopen_files_unchanged': True},
    'validation': {'mask': 1023, 'files_unchanged_after_install': True},
    'templates': {'mask': 262143, 'reopen_mask': 63, 'cold_reopen_files_unchanged': True},
    'boundaries': {'cases_checked': 18, 'record_bytes': 2872, 'files_unchanged': True},
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('runs', type=Path)
    parser.add_argument('boundaries', type=Path, help='Directory of the boundary run')
    args = parser.parse_args()
    data = args.disk.read_bytes()
    disk_sha = sha(data)
    pack = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
    source = runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['budget_source']
    delivered = pack['snapshot'](data)[1]
    inventory = json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())
    sources = {}
    for entry in inventory['entries']:
        name = entry['path']
        if name.startswith('Apps/Budget/'):
            payload = delivered['/'+name][2]
            if payload != source(entry):
                raise ValueError(f'Delivered Budget file differs: {name}')
            sources[name] = sha(payload)

    cases = {}
    for name, expected in CHECKS.items():
        path = (args.boundaries if name == 'boundaries' else args.runs/name)/'result.json'
        raw = path.read_bytes()
        report = json.loads(raw)
        if report.get('result') != 'pass' or not report.get('inputs_unchanged'):
            raise ValueError(f'{name}: workflow failed or inputs changed')
        actual_disk = report['disk_sha256'] if name == 'launch' else report['packaging']['source_sha256']
        if actual_disk != disk_sha or any(report.get(key) != value for key, value in expected.items()):
            raise ValueError(f'{name}: unexpected input disk or workflow result')
        cases[name] = {'receipt': str(path), 'sha256': sha(raw), **expected}

    result = {'result': 'pass', 'disk_sha256': disk_sha, 'application_sha256': sources, 'cases': cases}
    (args.runs/'suite-result.json').write_text(json.dumps(result, indent=2)+'\n')


if __name__ == '__main__':
    main()
