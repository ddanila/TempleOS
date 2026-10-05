#!/usr/bin/env python3
"""Require first CPU trap on an alternate stack without a prior debugger trap."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles=5):
    from copy import deepcopy
    checks=[deepcopy(c) for c in runpy.run_path(str(ROOT/'tools/test-i386-debug-public-stack.py'))['commands'](cycles)]
    checks[0]=(checks[0][0].replace('MAlloc(4096)','MAlloc(65536)').replace('CpuStackBuf+3072','CpuStackBuf+49152'),[])
    checks[4]=('Bool CpuTrapFind(){I64 n=MSize(CpuTrapBytes);while(CpuTrapOffset+2<n&&(CpuTrapBytes[CpuTrapOffset]!=0x90||CpuTrapBytes[CpuTrapOffset+1]!=0x90||CpuTrapBytes[CpuTrapOffset+2]!=0x90))CpuTrapOffset++;return CpuTrapOffset+2<n;}',[])
    checks[2]=('I64 CpuTrapInstruction(){U32 value=0,original,target=CpuStackTop;asm { MOV U32 &original[EBP],ESP MOV ESP,U32 &target[EBP] MOV EAX,0x11223344 NOP NOP NOP MOV EAX,ESP MOV U32 &value[EBP],EAX MOV ESP,U32 &original[EBP] }return value;}',[])
    for index,check in enumerate(checks):
        if len(check)!=3:continue
        source,answers,interaction=check
        rows=interaction['events'][2]['expect_rows']
        condition='Fs->rsp==CpuStackTop;'
        final=rows[:-1]+['dbg> '+condition,'1','dbg> ']
        interaction['events']=interaction['events'][:3]+[{'text':condition},{'key':'ret'},{'expect_rows':final,'label':'initial-physical-stack'},{'text':'G;'}]
        interaction['final_rows']=final[:-1]+['dbg> G;']
        checks[index]=(source,answers,interaction)
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
                  scope='First INT3 after switching physical ESP to allocated alternate stack, captured RSP, debugger expression, G physical result and exact saved ESP restoration; no prior debugger-stack anchor required, not private allocation audit')
    dependency = ROOT / 'tools/test-i386-debug-public-stack.py'
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
