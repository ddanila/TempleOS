#!/usr/bin/env python3
"""Enforce the planned 60-second normal-boot budget on no-FPU QEMU evidence.

This checks one timing verdict, not source provenance or complete M7 acceptance.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path


def assess(data):
    if not isinstance(data, dict):
        return {'result': 'invalid', 'errors': ['evidence must be a JSON object'],
                'budget_seconds': 60}
    expected = {'result': 'pass', 'cpu': '486,-fpu', 'ram_mib': 8,
                'boot_mode': 'interactive'}
    errors = [f'{key}: expected {value!r}, got {data.get(key)!r}'
              for key, value in expected.items() if data.get(key) != value]
    elapsed = data.get('startup_seconds')
    if (type(elapsed) not in (int, float) or not math.isfinite(elapsed)
            or elapsed <= 0):
        errors.append('startup_seconds must be a finite positive measurement')
    if errors:
        return {'result': 'invalid', 'errors': errors, 'budget_seconds': 60}
    return {'result': 'pass' if elapsed <= 60 else 'fail',
            'startup_seconds': elapsed, 'budget_seconds': 60,
            'over_budget_seconds': max(0, elapsed - 60)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('evidence', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.resolve() == args.evidence.resolve():
        parser.error('output must not overwrite input evidence')
    raw = args.evidence.read_bytes()
    report = assess(json.loads(raw))
    report.update(evidence=str(args.evidence.resolve()),
                  evidence_sha256=hashlib.sha256(raw).hexdigest(),
                  scope='Normal boot timing only; not complete M7 qualification')
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if report['result'] == 'pass' else
                     1 if report['result'] == 'fail' else 2)


if __name__ == '__main__':
    main()
