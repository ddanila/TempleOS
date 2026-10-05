#!/usr/bin/env python3
"""Inspect and edit each 386 general register through TaskRegAddr before S and G."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


REGISTERS = {'eax': 0, 'ecx': 1, 'edx': 2, 'ebx': 3, 'esi': 6, 'edi': 7}


def commands(cycles=1, register='eax'):
    checks = runpy.run_path(str(ROOT / 'tools/test-i386-debug-register-edit.py'))['commands'](cycles)
    source, answers = checks[2]
    checks[2] = (source.replace('EAX', register.upper()), answers)
    for check in checks:
        if len(check) != 3:
            continue
        interaction = check[2]
        for event in interaction['events']:
            if 'text' in event:
                event['text'] = event['text'].replace('TaskRegAddr(Fs,0)', f'TaskRegAddr(Fs,{REGISTERS[register]})')
            if 'expect_rows' in event:
                event['expect_rows'] = [row.replace('TaskRegAddr(Fs,0)', f'TaskRegAddr(Fs,{REGISTERS[register]})') for row in event['expect_rows']]
            if event.get('label') == 'captured-eax':
                event['label'] = 'captured-' + register
    return checks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--cycles', type=int, default=1)
    parser.add_argument('--register', choices=REGISTERS, default='eax')
    args = parser.parse_args()
    if not 1 <= args.cycles <= 20:
        parser.error('--cycles must be between 1 and 20')
    args.out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    disk_hash, checker_hash = sha(args.disk), sha(Path(__file__))
    report = {'result': 'fail', 'disk_sha256': disk_hash, 'checker_sha256': checker_hash, 'cycles': args.cycles, 'register': args.register,
              'original_contract_source_sha256': sha(ROOT / 'Kernel/KDbg.HC'),
              'scope': 'Native TDD: original TaskRegAddr I64 pointer API exposes the selected captured 386 register; editing it changes the next stepped store and final G result. Not full register or original-runtime oracle coverage.'}
    try:
        dependencies = [ROOT / 'tools/test-i386-debug-register-edit.py', ROOT / 'tools/test-i386-debug-single-step.py', ROOT / 'tools/test-i386-debug-cpu-trap.py']
        report['dependency_sha256'] = {str(p.relative_to(ROOT)): sha(p) for p in dependencies}
        selected = commands(args.cycles,args.register)
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
