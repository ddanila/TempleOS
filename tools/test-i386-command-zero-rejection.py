#!/usr/bin/env python3
"""Prove VGA rejection detects completed zero results without rejecting ordinary zero answers."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--accel', choices=('tcg', 'kvm'), default='tcg')
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use fresh output')
    out.mkdir(parents=True)
    runner = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, runner, Path(__file__))}
    run = runpy.run_path(str(runner))['run_input']
    report = dict(result='running', input_sha256=pins, accel=args.accel,
                  scope='VGA rejection harness regression, not OS/source qualification')
    try:
        for case in ('negative', 'ordinary'):
            disk = out / (case + '.img')
            shutil.copyfile(args.disk, disk)
            check = dict(status='ok', answers=[], command_timeout=120)
            if case == 'negative':
                check.update(commands=[('0;', ['1'])], rejected_answers=['0'])
                try:
                    run(disk, out / case, startup_check=check, snapshot=False,
                        ram_mib=16, cpu='486,-fpu', accel=args.accel, qmp_stdio=True)
                except RuntimeError as error:
                    if 'Guest command returned a rejected answer on VGA' not in str(error):
                        raise
                    if not (out / case / 'startup-command-00-detected.png').is_file():
                        raise AssertionError('Rejected VGA frame not preserved')
                    report['negative'] = str(error)
                else:
                    raise AssertionError('Known zero answer was accepted as one')
            else:
                check.update(commands=[('0;', ['0']), ('1;', ['1'])])
                report['ordinary'] = run(disk, out / case, startup_check=check,
                    snapshot=False, ram_mib=16, cpu='486,-fpu', accel=args.accel, qmp_stdio=True)
        if any(sha(Path(p)) != h for p, h in pins.items()):
            raise ValueError('Harness inputs changed')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print('PASS: zero rejection and ordinary zero/one answers')


if __name__ == '__main__':
    main()
