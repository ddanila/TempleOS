#!/usr/bin/env python3
"""Measure stages of native document loading using bounded Bible excerpts."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import re
import threading
import time

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk', type=Path)
    ap.add_argument('--out', type=Path, required=True)
    sizes = ap.add_mutually_exclusive_group()
    sizes.add_argument('--large', action='store_true', help='Use 1600–6400-line excerpts')
    sizes.add_argument('--medium', action='store_true', help='Use 1600 and 3200 lines')
    args = ap.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-bible-load-profile/Contract.HC'
    bible = ROOT/'Misc/Bible.TXT'
    inputs = [source, fixture, bible, Path(__file__).resolve()] + [ROOT/p for p in (
        'tools/package-i386-native-image.py', 'tools/build-i386-kernel.py',
        'tools/test-i386-timeclock-welcome.py', 'tools/i386-kernel-input.py', 'Kernel/FontStd.HC')]
    pins = {str(p): sha(p) for p in inputs}
    lines = bible.read_bytes().splitlines(keepends=True)
    lengths = (1600, 3200, 4800, 6400) if args.large else (1600, 3200) if args.medium else (400, 800, 1200, 1600)
    files = {'/Probe/BibleProfile.HC': fixture.read_bytes()}
    files.update({f'/Probe/Bible{n}.TXT': b''.join(lines[:n]) for n in lengths})
    if len(lines) < max(lengths):
        raise ValueError('Bible source too short')
    out.mkdir(parents=True)
    working = out/'working.img'
    report = {'result': 'running', 'input_sha256': pins,
              'scope': 'Host-observed elapsed stages for bounded native Bible excerpts; not full-file performance qualification',
              'sample_sha256': {str(n): hashlib.sha256(files[f'/Probe/Bible{n}.TXT']).hexdigest() for n in lengths}}
    report['packaging'] = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](source, working, additions=files)
    log = out/'guest/debug.log'
    stamps = {}
    stopped = threading.Event()
    def observe():
        while not stopped.wait(.1):
            if log.exists():
                for line in log.read_text(errors='replace').splitlines():
                    if line.startswith('BIBLE PROFILE '):
                        stamps.setdefault(line, time.monotonic())
    watcher = threading.Thread(target=observe, daemon=True)
    watcher.start()
    try:
        call = 'BibleProfileLarge' if args.large else 'BibleProfileMedium' if args.medium else 'BibleProfileAll'
        commands = ['#include "C:/Probe/BibleProfile.HC"',
                    f"if(!{call})throw('BP',TRUE);", '6*7;']
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](
            working, out/'guest', commands, 64, True, command_timeout=1200)
        observed = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](working, set(files))
        if observed != files:
            raise ValueError('Delivered files changed')
        phases = ('read-begin','read-end','put-begin','put-end','layout-end','find-end','free-end')
        times = {}
        for n in lengths:
            values = [stamps[f'BIBLE PROFILE {n} {phase}'] for phase in phases]
            if values != sorted(values):
                raise ValueError('Profile markers out of order')
            times[str(n)] = {phases[i]: round(values[i]-values[0], 3) for i in range(len(phases))}
        region_rows = re.findall(r'^BIBLE REGIONS (\d+) (\d+)$', log.read_text(), re.M)
        regions = {int(n): int(count) for n,count in region_rows}
        if set(regions) != set(lengths):
            raise ValueError('Missing region-count markers')
        report.update(result='pass', elapsed_seconds=times, region_counts=regions)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        stopped.set(); watcher.join()
        if stamps:
            first = min(stamps.values())
            report['observed_markers_seconds'] = {key: round(value-first, 3) for key,value in stamps.items()}
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
