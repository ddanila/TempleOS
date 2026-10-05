#!/usr/bin/env python3
"""Require managed INT3 rewind, original-instruction step, rearm and removal."""
import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles=1):
    base = runpy.run_path(str(ROOT / 'tools/test-i386-debug-single-step.py'))['commands']()
    checks = [deepcopy(check) for check in base]
    checks[6] = ('U0 CpuTrapPatch(){BptS(CpuTrapBytes+CpuTrapOffset+3);}', [])
    checks[7] = ('CpuTrapPatch;CpuTrapBytes[CpuTrapOffset+3]==0xCC;', ['1'])
    # The managed breakpoint replaces the store opcode, not a disposable NOP.
    # S must restore and execute that instruction, rather than skip one byte.
    tail = [('CpuTrapPatch;', [])] + checks[9:] + [
        ('CpuTrapBytes[CpuTrapOffset+3]==0xCC;', ['1']),
        ('B2;', ['1']),
        ('CpuTrapBytes[CpuTrapOffset+3]!=0xCC&&Fs->bpt_lst==0;', ['1']),
    ]
    return checks[:9] + [deepcopy(check) for _ in range(cycles) for check in tail]


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
              'scope': 'Native TDD: managed BptS replaces a real store opcode; trap must rewind, S executes restored instruction, G rearms and B2 removes. Not shared-code/task ownership or full debugger coverage.'}
    try:
        dependencies = [ROOT / 'tools/test-i386-debug-single-step.py', ROOT / 'tools/test-i386-debug-cpu-trap.py']
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
