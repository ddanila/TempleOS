#!/usr/bin/env python3
"""Require nested exception catch and yielding from an actual CPU debugger."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles=5):
    from copy import deepcopy
    checks=[deepcopy(c) for c in runpy.run_path(str(ROOT/'tools/test-i386-debug-cpu-trap.py'))['commands'](cycles)]
    checks.insert(9,("I64 CpuNestedCatch(){I64 n=0;try{throw('Nested');}catch{Sleep(10);n=42;Fs->catch_except=TRUE;}return n;}",[]))
    for index,check in enumerate(checks):
        if len(check)!=3:continue
        source,answers,interaction=check
        rows=interaction['events'][2]['expect_rows']
        condition='CpuNestedCatch==42;'
        final=rows[:-1]+['dbg> '+condition,'1','dbg> ']
        interaction['events'][-1:]=[{'text':condition},{'key':'ret'},{'expect_rows':final,'label':'nested-catch-yield'},{'text':'G;'}]
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
                  scope='Actual CPU debugger command throws, catches and sleeps on debugger execution stack, then G and mode/IF/TF/heap recovery; not frame walking or allocation failure coverage')
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
