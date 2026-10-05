#!/usr/bin/env python3
"""Require public RSP editing to select the physical stack on CPU debugger resume."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles=1):
    from copy import deepcopy
    base = runpy.run_path(str(ROOT / 'tools/test-i386-debug-cpu-trap.py'))['commands'](cycles)
    checks = [deepcopy(check) for check in base]
    checks[0] = (checks[0][0] + 'U8 *CpuStackBuf=MAlloc(4096);I64 CpuStackTop=(CpuStackBuf+3072)(U64);', [])
    checks[2] = ('I64 CpuTrapInstruction(){U32 value=0;asm { MOV EAX,0x11223344 NOP NOP NOP NOP NOP NOP NOP MOV EAX,ESP MOV U32 &value[EBP],EAX MOV ESP,EBP }return value;}', [])
    checks.insert(8, ('U0 CpuStackEdit(){Fs->rsp=CpuStackTop;}', []))
    for index, check in enumerate(checks):
        if len(check) != 3:
            if check[0] == 'CpuTrapResult==0x11223344;':
                checks[index] = ('CpuTrapResult==CpuStackTop;', ['1'])
            continue
        source, answers, interaction = check
        rows = interaction['events'][2]['expect_rows']
        condition = 'Fs->rsp==CpuStackTop;'
        edited = rows[:-1] + ['dbg> CpuStackEdit;', 'dbg> ' + condition, '1', 'dbg> ']
        interaction['events'] = interaction['events'][:-1] + [
            {'text':'CpuStackEdit;'}, {'key':'ret'},
            {'text':condition}, {'key':'ret'},
            {'expect_rows':edited,'label':'public-stack-selected'},
            {'text':'G;'},
        ]
        interaction['final_rows'] = edited[:-1] + ['dbg> G;']
        checks[index] = (source,answers,interaction)
    return checks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--cycles', type=int, default=1,
                        help='Repeated trap/resume cycles; first warms resource accounting')
    args = parser.parse_args()
    if args.cycles < 1 or args.cycles > 20:
        parser.error('--cycles must be between 1 and 20')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, disk = sha(Path(__file__)), sha(args.disk)
    report = dict(checker_sha256=checker, disk_sha256=disk, cycles=args.cycles,
                  scope='Public RSP edit, physical MOV EAX,ESP after G on allocated alternate stack, original EBP-based stack restoration, debugger mode/IF/TF and heap recovery; not S or other-task stack controls')
    dependency = ROOT / 'tools/test-i386-debug-cpu-trap.py'
    report['dependency_sha256'] = sha(dependency)
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands(args.cycles)})
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
