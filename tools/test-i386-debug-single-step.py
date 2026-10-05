#!/usr/bin/env python3
"""Require S to execute one instruction, reenter the debugger, then permit G."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    checks = runpy.run_path(str(ROOT / 'tools/test-i386-debug-cpu-trap.py'))['commands']()
    checks[0] = (checks[0][0] + 'I64 CpuStepFinal=0;U32 *CpuStepValue=0;', [])
    checks[2] = ('I64 CpuTrapInstruction(){U32 value=0;CpuStepFinal=0;CpuStepValue=&value;asm { MOV EAX,0x11223344 NOP NOP NOP MOV U32 &value[EBP],EAX }CpuStepFinal=1;return value;}', [])
    checks[4] = ('Bool CpuTrapFind(){I64 n=MSize(CpuTrapBytes);while(CpuTrapOffset+2<n&&(CpuTrapBytes[CpuTrapOffset]!=0x90||CpuTrapBytes[CpuTrapOffset+1]!=0x90||CpuTrapBytes[CpuTrapOffset+2]!=0x90))CpuTrapOffset++;return CpuTrapOffset+2<n;}', [])
    checks[6] = ('U0 CpuTrapPatch(){CpuTrapBytes[CpuTrapOffset+2]=0xCC;}', [])
    checks[7] = ('CpuTrapPatch;CpuTrapBytes[CpuTrapOffset+2]==0xCC;', ['1'])
    source, answers, interaction = checks[9]
    heading = interaction['initial_rows']
    condition = 'CpuStepValue[0]==0x11223344&&CpuStepFinal==0;'
    before = 'CpuStepValue[0]==0&&CpuStepFinal==0;'
    interaction['events'] = [
        {'text': before}, {'key': 'ret'},
        {'expect_rows': heading[:-1] + ['dbg> ' + before, '1', 'dbg> '], 'label': 'before-step'},
        {'text': 'S;'}, {'key': 'ret'},
        {'expect_rows': heading, 'label': 'step-reentry'},
        {'text': condition}, {'key': 'ret'},
        {'expect_rows': heading[:-1] + ['dbg> ' + condition, '1', 'dbg> '], 'label': 'one-store'},
        {'text': 'G;'},
    ]
    interaction['final_rows'] = heading[:-1] + ['dbg> ' + condition, '1', 'dbg> G;']
    checks[9] = (source, answers, interaction)
    checks.append(('CpuStepFinal==1;', ['1']))
    return checks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    disk_hash, checker_hash = sha(args.disk), sha(Path(__file__))
    report = {'result': 'fail', 'disk_sha256': disk_hash, 'checker_sha256': checker_hash,
              'original_contract_source_sha256': sha(ROOT / 'Kernel/KDbg.HC'),
              'scope': 'Native TDD: S executes the store immediately after INT3, reenters before function return; G then completes with EAX result and restored flags/mode. Not an original-runtime oracle or managed breakpoint test.'}
    try:
        selected = commands()
        if any(len(command[0]) > 255 for command in selected):
            raise ValueError('Single-step helper exceeds console input limit')
        report['behavior'] = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input'](
            args.disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
            startup_check={'status': 'ok', 'answers': [], 'commands': selected})
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
