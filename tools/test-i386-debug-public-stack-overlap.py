#!/usr/bin/env python3
"""Require debugger return-frame relocation to handle overlapping stack ranges."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles=1, delta=-4):
    from copy import deepcopy
    if delta not in (-4, 4):
        raise ValueError('Overlap displacement must be -4 or +4')
    checks = [deepcopy(check) for check in runpy.run_path(str(ROOT / 'tools/test-i386-debug-public-stack.py'))['commands'](cycles)]
    checks[0] = (checks[0][0].split('U8 *CpuStackBuf=')[0] + 'I64 CpuStackTop=0;', [])
    for index, check in enumerate(checks):
        if check[0] == 'U0 CpuStackEdit(){Fs->rsp=CpuStackTop;}':
            checks[index] = (f'U0 CpuStackEdit(){{CpuStackTop=Fs->rsp{delta:+d};Fs->rsp=CpuStackTop;}}', [])
    return checks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--cycles', type=int, default=1,
                        help='Repeated trap/resume cycles; first warms resource accounting')
    parser.add_argument('--delta', type=int, choices=(-4,4), default=-4)
    args = parser.parse_args()
    if args.cycles < 1 or args.cycles > 20:
        parser.error('--cycles must be between 1 and 20')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, disk = sha(Path(__file__)), sha(args.disk)
    report = dict(checker_sha256=checker, disk_sha256=disk, cycles=args.cycles, delta=args.delta,
                  scope='Public RSP +/-4 edit, overlapping 68-byte exception return-frame relocation, physical MOV EAX,ESP after G, original EBP restoration and mode/IF/TF/heap checks; not S or other-task controls')
    dependency = ROOT / 'tools/test-i386-debug-public-stack.py'
    report['dependency_sha256'] = sha(dependency)
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands(args.cycles, args.delta)})
        if sha(dependency) != report['dependency_sha256']:
            raise ValueError('CPU fixture changed during flags qualification')
        if sha(Path(__file__)) != checker:
            raise ValueError('CPU trap checker changed during execution')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['source_disk_unchanged'] = sha(args.disk) == disk
        if not report['source_disk_unchanged']:
            report.update(result='fail', error='CPU trap check modified source disk')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
