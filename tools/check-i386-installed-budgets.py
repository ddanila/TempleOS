#!/usr/bin/env python3
"""Enforce installed workstation startup and visible-response budgets."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def assess_job(name, data):
    assess_startup = runpy.run_path(str(ROOT / 'tools/check-i386-startup-budget.py'))['assess']
    boots = {}
    latencies = {}
    errors = []
    if name == 'workstation':
        boots['workstation'] = data
        latencies['long_document_up_to_vga'] = data.get(
            'interaction_latencies_seconds', {}).get('long_document_up_to_vga')
    elif name == 'large-source':
        boots['large-source'] = data.get('behavior', {})
    elif name == 'doldoc-session':
        for phase in ('create_edit_save', 'reopen_after_boot', 'revised_after_second_boot'):
            boots[phase] = data.get(phase, {})
        latencies['interrupt_to_recovery_vga'] = boots['create_edit_save'].get(
            'interaction_latencies_seconds', {}).get('interrupt_to_recovery_vga')
    else:
        return {'result': 'pass', 'scope': 'No startup/latency budget measured by this job'}
    verdicts = {}
    for phase, evidence in boots.items():
        verdict = assess_startup(evidence)
        verdicts[phase] = verdict
        if verdict['result'] != 'pass':
            errors.append(phase + ': startup budget ' + verdict['result'])
    for measurement, elapsed in latencies.items():
        if (type(elapsed) not in (int, float) or not math.isfinite(elapsed)
                or elapsed <= 0 or elapsed > 1):
            errors.append(measurement + ': expected positive finite latency <= 1 second')
    return dict(result='fail' if errors else 'pass', errors=errors,
                startup=verdicts, latency_seconds=latencies, latency_budget_seconds=1)


def assess(report):
    jobs = report.get('jobs', {})
    required = {'workstation', 'doldoc-session', 'speaker', 'resource'}
    version = report.get('qualification_version', 1)
    if version == 2:
        required.add('large-source')
    elif version != 1:
        return dict(result='invalid', errors=['Unsupported qualification version'])
    if report.get('result') != 'pass' or set(jobs) != required:
        return dict(result='invalid', errors=['Require a complete passing qualification report'])
    results = {}
    for name in sorted(required):
        data = jobs[name].get('result')
        if not isinstance(data, dict) or data.get('result') != 'pass':
            return dict(result='invalid', errors=[name + ': missing passing job evidence'])
        results[name] = assess_job(name, data)
    return dict(result='pass' if all(r['result'] == 'pass' for r in results.values()) else 'fail',
                jobs=results, scope='Startup and visible latency only; not complete release acceptance')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('evidence', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists() or args.out.resolve() == args.evidence.resolve():
        parser.error('Use a fresh output report')
    raw = args.evidence.read_bytes()
    result = assess(json.loads(raw))
    result.update(evidence=str(args.evidence.resolve()),
                  evidence_sha256=hashlib.sha256(raw).hexdigest())
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))
    raise SystemExit(0 if result['result'] == 'pass' else 1)


if __name__ == '__main__':
    main()
