#!/usr/bin/env python3
"""Require captured ESP/EBP inspection to match the interrupted function."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles=1):
    base = runpy.run_path(str(ROOT / 'tools/test-i386-debug-cpu-trap.py'))['commands']()
    from copy import deepcopy
    checks = [deepcopy(check) for check in base]
    checks[0] = (checks[0][0] + 'U32 *CpuFrameSp=0,*CpuFrameBp=0;', [])
    checks[2] = ('I64 CpuTrapInstruction(){U32 s=0,b=0;CpuFrameSp=&s;CpuFrameBp=&b;asm { MOV EAX,ESP MOV U32 &s[EBP],EAX MOV EAX,EBP MOV U32 &b[EBP],EAX NOP NOP NOP }return 0x11223344;}', [])
    checks[4] = ('Bool CpuTrapFind(){I64 n=MSize(CpuTrapBytes);while(CpuTrapOffset+2<n&&(CpuTrapBytes[CpuTrapOffset]!=0x90||CpuTrapBytes[CpuTrapOffset+1]!=0x90||CpuTrapBytes[CpuTrapOffset+2]!=0x90))CpuTrapOffset++;return CpuTrapOffset+2<n;}', [])
    source, answers, interaction = checks[9]
    heading = interaction['initial_rows']
    inspect = 'TaskRegAddr(Fs,4)[0]==CpuFrameSp[0]&&TaskRegAddr(Fs,5)[0]==CpuFrameBp[0];'
    interaction['events'] = [
        {'text': inspect}, {'key': 'ret'},
        {'expect_rows': heading[:-1] + ['dbg> ' + inspect, '1', 'dbg> '], 'label': 'captured-stack-registers'},
        {'text': 'G;'},
    ]
    interaction['final_rows'] = heading[:-1] + ['dbg> ' + inspect, '1', 'dbg> G;']
    checks[9] = (source, answers, interaction)
    return checks[:9] + [deepcopy(check) for _ in range(cycles) for check in checks[9:]]


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
              'scope': 'Native TDD: TaskRegAddr ESP/EBP slots match assembly snapshots taken immediately before INT3, then G preserves function result and flags/mode. Not stack-pointer editing or complete debugger coverage.'}
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
            raise ValueError('Stack-register fixture changed during execution')
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
