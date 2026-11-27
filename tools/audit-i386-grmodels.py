#!/usr/bin/env python3
"""Validate five GrModels workflow captures against the pinned original."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT/'build/grmodels-menu-workflows-v1'
GENERATIONS = ROOT/'build/i386-code-alloc-known-v1/native-generations128'
MESHES = {'ball': MENU/'ball-original-final', 'man': MENU/'man-original-tab'}
CANCELLATIONS = {
    'cancel': GENERATIONS/'grmodels-cancel-original-shift',
    'ball-lighting-cancel': GENERATIONS/'grmodels-ball-lighting-cancel-original',
    'man-form-cancel': GENERATIONS/'grmodels-man-form-cancel-original',
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def audit(disk, runs):
    image = disk.read_bytes()
    disk_sha = sha(image)
    snapshot = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['snapshot']
    files = snapshot(image)[1]
    delivered = {name: record[2] for name, record in files.items()
                 if name.startswith('/Apps/GrModels/')}
    current = {'/'+str(path.relative_to(ROOT)): path.read_bytes()
               for path in (ROOT/'Apps/GrModels').rglob('*') if path.is_file()}
    if delivered != current:
        raise ValueError('Disk does not contain the current bundled GrModels files')
    entries = json.loads((ROOT/'docs/i386-compatibility-inventory.json').read_text())['entries']
    expected_reference = {entry['path']: entry['reference_sha256'] for entry in entries
                          if entry['path'].startswith('Apps/GrModels/')}

    manifest = {}
    for model, reference in (MESHES | CANCELLATIONS).items():
        case = runs/model
        report_path = case/'result.json'
        report = json.loads(report_path.read_text())
        original_path = reference/'result.json'
        original = json.loads(original_path.read_text())
        if report['result'] != 'pass' or original['result'] != 'pass':
            raise ValueError(f'{model}: a workflow failed')
        if report['model'] != model or original['model'] != model:
            raise ValueError(f'{model}: mismatched workflow receipts')
        if original['application_sha256'] != expected_reference:
            raise ValueError(f'{model}: reference receipt does not match the pinned files')
        if report['package']['source_sha256'] != disk_sha or not report['package']['source_unchanged']:
            raise ValueError(f'{model}: native receipt does not match the input disk')
        if report['package']['added_files'] != {'/ModelsProbe.HC': report['workflow_sha256']}:
            raise ValueError(f'{model}: installed fixture does not match the receipt')
        if not report.get('fresh_arithmetic'):
            raise ValueError(f'{model}: missing fresh native prompt output')
        row = {'native_receipt_sha256': sha(report_path.read_bytes()),
               'reference_receipt_sha256': sha(original_path.read_bytes())}
        if model in MESHES:
            a = (reference/'guest/MenuMesh.bin').read_bytes()
            b = (case/'guest/MenuMesh.bin').read_bytes()
            if a != b or sha(a) != original['mesh']['sha256'] or sha(b) != report['mesh']['sha256']:
                raise ValueError(f'{model}: mesh bytes differ')
            row['mesh'] = report['mesh']
        elif report['mesh'] is not None or original['mesh'] is not None:
            raise ValueError(f'{model}: cancellation produced a mesh')
        manifest[model] = row
    if sha(disk.read_bytes()) != disk_sha:
        raise ValueError('Disk changed during the audit')
    return {'result': 'pass', 'disk_sha256': disk_sha,
            'application_sha256': {name: sha(data) for name, data in sorted(delivered.items())},
            'cases': manifest}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('runs', type=Path)
    args = parser.parse_args()
    result = audit(args.disk, args.runs)
    (args.runs/'suite-result.json').write_text(json.dumps(result, indent=2)+'\n')


if __name__ == '__main__':
    main()
