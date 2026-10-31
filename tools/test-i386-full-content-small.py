#!/usr/bin/env python3
"""Verify a full content image and bounded native access to small bundled data."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('image', type=Path)
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    source, out = args.image.resolve(), args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    inventory = ROOT/'docs/i386-compatibility-inventory.json'
    fixture = ROOT/'tests/guest/i386-full-content/Small.HC'
    paths = [source, inventory, fixture, Path(__file__).resolve()] + [ROOT/p for p in (
        'tools/build-i386-kernel.py', 'tools/package-i386-native-image.py',
        'tools/i386-kernel-input.py', 'tools/test-i386-timeclock-welcome.py', 'Kernel/FontStd.HC')]
    entries = json.loads(inventory.read_text())['entries']
    paths += [ROOT/e['path'] for e in entries]
    pins = {str(p): sha(p) for p in paths}
    report = {'result':'running', 'scope':'All inventory bytes against current workspace and bounded guest lookup/small-file read; not application or desktop qualification', 'input_sha256':pins}
    try:
        helper = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        wanted = {'/'+e['path'] for e in entries}
        actual = helper['mutated_file_contents'](source, wanted)
        bad = [e['path'] for e in entries if '/'+e['path'] not in actual or
               hashlib.sha256(actual['/'+e['path']]).hexdigest() != pins[str(ROOT/e['path'])]]
        if bad:
            raise ValueError(f'Inventory content mismatch: {bad[:8]}')
        report['inventory_count'] = len(entries)
        report['reference_identical'] = sum(pins[str(ROOT/e['path'])] == e['reference_sha256'] for e in entries)
        report['workspace_modified'] = len(entries)-report['reference_identical']
        report['filesystem'] = helper['verify_mutated_volume'](source)
        files = {'/Probe/FullContent.HC':fixture.read_bytes()}
        disk = out/'working.img'
        report['packaging'] = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](source, disk, additions=files)
        commands = ['#include "C:/Probe/FullContent.HC"', "if(FullContentContract!=63)throw('Content',TRUE);", '6*7;']
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](disk, out/'guest', commands, 64, True, command_timeout=180)
        if helper['mutated_file_contents'](disk, set(files)) != files:
            raise ValueError('Delivered fixture changed')
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(p.is_file() and sha(p) == pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
