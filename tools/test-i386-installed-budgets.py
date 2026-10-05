#!/usr/bin/env python3
"""Mutate real passing runtime evidence to test release-budget rejection."""
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('workstation', 'session', 'out'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output report')
    inputs = [args.workstation, args.session, Path(__file__),
              ROOT / 'tools/check-i386-installed-budgets.py',
              ROOT / 'tools/check-i386-startup-budget.py']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in inputs}
    assess = runpy.run_path(str(inputs[-2]))['assess_job']
    workstation = json.loads(args.workstation.read_text())
    session = json.loads(args.session.read_text())
    assert assess('workstation', workstation)['result'] == 'pass'
    assert assess('doldoc-session', session)['result'] == 'pass'
    cases = []

    def reject(name, data, label):
        if assess(name, data)['result'] != 'fail':
            raise AssertionError('Accepted invalid budget evidence: ' + label)
        cases.append(label)

    for phase in ('create_edit_save', 'reopen_after_boot', 'revised_after_second_boot'):
        for label, value in [('over budget', 60.001), ('NaN', float('nan')),
                             ('zero', 0), ('missing', None)]:
            bad = deepcopy(session)
            bad[phase]['startup_seconds'] = value
            reject('doldoc-session', bad, phase + ' startup ' + label)
    for label, value in [('over budget', 1.001), ('infinite', float('inf')),
                         ('zero', 0), ('missing', None)]:
        bad = deepcopy(session)
        bad['create_edit_save']['interaction_latencies_seconds']['interrupt_to_recovery_vga'] = value
        reject('doldoc-session', bad, 'interrupt latency ' + label)
    bad = deepcopy(workstation)
    bad['startup_seconds'] = 60.001
    reject('workstation', bad, 'workstation startup over budget')
    bad = deepcopy(workstation)
    del bad['interaction_latencies_seconds']['long_document_up_to_vga']
    reject('workstation', bad, 'workstation visible-update latency missing')
    if any(sha(Path(p)) != digest for p, digest in pins.items()):
        raise ValueError('Budget evidence or helpers changed')
    report = dict(result='pass', rejected_cases=cases, input_sha256=pins,
                  scope='Recorded timing and targeted evidence mutations; not new runtime qualification')
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2) + '\n')
    print('PASS: two real passing records and ' + str(len(cases)) + ' rejected budget mutations')


if __name__ == '__main__':
    main()
