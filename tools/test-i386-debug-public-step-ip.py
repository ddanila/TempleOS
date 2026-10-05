#!/usr/bin/env python3
"""Require direct public RIP editing to select the instruction for default S."""
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles=1):
    checks = runpy.run_path(str(ROOT / 'tools/test-i386-debug-public-ip.py'))['commands'](cycles)
    for index, check in enumerate(checks):
        if len(check) != 3:
            continue
        source, answers, interaction = check
        heading = interaction['initial_rows']
        condition = 'CpuStepValue[0]==0x11223344&&CpuStepFinal==0;'
        interaction['events'][-1:] = [
            {'text': 'S;'}, {'key': 'ret'},
            {'expect_rows': heading, 'label': 'address-step-reentry'},
            {'text': condition}, {'key': 'ret'},
            {'expect_rows': heading[:-1] + ['dbg> ' + condition, '1', 'dbg> '], 'label': 'address-stepped-store'},
            {'text': 'G;'},
        ]
        interaction['final_rows'] = heading[:-1] + ['dbg> ' + condition, '1', 'dbg> G;']
        checks[index] = (source, answers, interaction)
    return checks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--cycles', type=int, default=1)
    args = parser.parse_args()
    if not 1 <= args.cycles <= 20:
        parser.error('--cycles must be between 1 and 20')
    args.out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    disk_hash, checker_hash = sha(args.disk), sha(Path(__file__))
    report = {'result': 'fail', 'disk_sha256': disk_hash, 'checker_sha256': checker_hash, 'cycles': args.cycles,
              'original_contract_source_sha256': sha(ROOT / 'Kernel/KDbg.HC'),
              'scope': 'Native TDD: direct public RIP edit followed by S skips verified MOV EAX,imm32 and executes the chosen store before reentry; G preserves the marker. Not stack/flags edits, other-task or full debugger coverage.'}
    try:
        dependencies = [ROOT / 'tools/test-i386-debug-public-ip.py', ROOT / 'tools/test-i386-debug-go-address.py', ROOT / 'tools/test-i386-debug-single-step.py', ROOT / 'tools/test-i386-debug-cpu-trap.py']
        report['dependency_sha256'] = {str(p.relative_to(ROOT)): sha(p) for p in dependencies}
        selected = commands(args.cycles)
        if any(len(command[0]) > 255 for command in selected):
            raise ValueError('Single-step helper exceeds console input limit')
        report['behavior'] = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input'](
            args.disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
            startup_check={'status': 'ok', 'answers': [], 'commands': selected})
        if any(sha(ROOT / name) != digest for name, digest in report['dependency_sha256'].items()):
            raise ValueError('Register checker dependency changed during execution')
        if sha(Path(__file__)) != checker_hash:
            raise ValueError('Single-step checker changed during execution')
        report['result'] = 'pass'
    except Exception as exc:
        report['error'] = str(exc)
        raise
    finally:
        report['source_disk_unchanged'] = sha(args.disk) == disk_hash
        if not report['source_disk_unchanged']:
            report.update(result='fail', error='Single-step test changed source disk')
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
