#!/usr/bin/env python3
"""Verify retained raw boot samples and summarize heap-validation callers."""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path


def summarize(directory):
    report_path, samples_path = directory / 'result.json', directory / 'samples.json'
    report = json.loads(report_path.read_text())
    samples = json.loads(samples_path.read_text())
    counts, stacks, heap_callers = defaultdict(Counter), defaultdict(Counter), defaultdict(Counter)
    for sample in samples:
        phase, symbol = sample['phase'], sample['symbol']
        chain = [symbol] + [caller['symbol'] for caller in sample['callers']]
        counts[phase][symbol] += 1
        stacks[phase][' <- '.join(chain)] += 1
        if symbol == 'Kernel:I386HeapScan':
            heap_callers[phase][' <- '.join(chain[1:4])] += 1
    if (len(samples) != report['samples'] or
            dict(counts) != report['phases'] or dict(stacks) != report['stacks']):
        raise ValueError(f'{directory}: raw samples disagree with report')
    log = (directory / 'debug.log').read_text()
    if 'STARTUP source ok\n' not in log or 'DONE native kernel startup\n' not in log:
        raise ValueError(f'{directory}: successful startup markers missing')
    if report['source_disk_unchanged'] is not True:
        raise ValueError(f'{directory}: source disk preservation unproven')
    return {
        'directory': str(directory.resolve()),
        'evidence_sha256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                            for p in (report_path, samples_path, directory / 'debug.log')},
        'disk_sha256': report['disk_sha256'], 'samples': len(samples),
        'phases': {phase: {
            'samples': sum(counter.values()),
            'top_symbols': dict(counter.most_common(10)),
            'heap_scan_callers': dict(heap_callers[phase].most_common()),
        } for phase, counter in counts.items()},
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('profiles', type=Path, nargs='+')
    args = parser.parse_args()
    print(json.dumps({
        'scope': 'Verified statistical sample attribution; not timing, call counts, or acceptance.',
        'profiles': [summarize(directory) for directory in args.profiles],
    }, indent=2))


if __name__ == '__main__':
    main()
