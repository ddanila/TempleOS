#!/usr/bin/env python3
"""Require a debugger-stack exception trace to identify its compiled caller."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles=5):
    from copy import deepcopy
    checks=[deepcopy(c) for c in runpy.run_path(str(ROOT/'tools/test-i386-debug-cpu-nested-catch.py'))['commands'](cycles)]
    checks[0]=(checks[0][0]+'U8 *CpuTraceAddr=0;I64 CpuTraceSize=0;',[])
    index=next(i for i,c in enumerate(checks) if c[0].startswith('I64 CpuNestedCatch()'))
    source,answers=checks[index]
    checks[index]=(source.replace('n=42;','n=CpuTraceValid;'),answers)
    checks[index:index]=[('Bool CpuTraceValid(){U8 *p=Fs->except_callers[0];return p>=CpuTraceAddr&&p<CpuTraceAddr+CpuTraceSize;}',[])]
    index=next(i for i,c in enumerate(checks) if c[0]=='CpuTrapProbe;')
    checks[index:index]=[('U0 CpuTraceBind(){CpuTraceAddr=(&CpuNestedCatch+0)(U64);CpuTraceSize=MSize(CpuTraceAddr);}',[]),('CpuTraceBind;CpuTraceSize>0;',['1'])]
    for i,check in enumerate(checks):
        if len(check)!=3:continue
        source,answers,interaction=check
        for event in interaction['events']:
            if 'text' in event:event['text']=event['text'].replace('CpuNestedCatch==42;','CpuNestedCatch==1;')
            if 'expect_rows' in event:event['expect_rows']=[r.replace('CpuNestedCatch==42;','CpuNestedCatch==1;') for r in event['expect_rows']]
        interaction['final_rows']=[r.replace('CpuNestedCatch==42;','CpuNestedCatch==1;') for r in interaction['final_rows']]
        checks[i]=(source,answers,interaction)
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
                  scope='Actual CPU debugger catch yields and requires except_callers[0] within the live compiled throwing function allocation; G and mode/IF/TF/heap recovery, not every frame or allocation failure')
    dependency = ROOT / 'tools/test-i386-debug-cpu-nested-catch.py'
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
