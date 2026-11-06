#!/usr/bin/env python3
"""Check TaskCaller against captured CPU registers and real debugger-stack callers."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles=1):
    from copy import deepcopy
    #The base fixture repeats references to its interaction dictionary. Each
    #cycle needs its own copy before inserting the caller inspection commands.
    checks = [deepcopy(check) for check in
              runpy.run_path(str(ROOT / 'tools/test-i386-debug-cpu-trap.py'))['commands'](cycles)]
    helpers = [
        'Bool TCCpuRange(U8 *n,U8 *p){CHashFun *f=HashFind(n,Fs->hash_table,HTT_FUN);if(!f||!f->dbg_info)return FALSE;CDbgInfo *d=f->dbg_info;return d->body[0]<=(p+0)(U64)<d->body[d->max_line+1-d->min_line];}',
        'I64 TCCpuSaved(){return (TaskCaller(Fs,0,TRUE)==Fs->rip)+2*(TaskCaller(NULL,0,TRUE)==CpuTrapBytes+CpuTrapOffset+1)+4*TCCpuRange("CpuTrapProbe",TaskCaller(Fs,1,TRUE));}',
        'I64 TCCpuCheck(){return TCCpuSaved+8*(TaskCaller(Fs,128,TRUE)==NULL)+16*TCCpuRange("TCCpuCheck",TaskCaller(NULL,0,FALSE));}',
    ]
    checks[9:9] = [(helper, []) for helper in helpers]
    if any(len(check[0]) > 255 for check in checks):
        raise ValueError('Debugger fixture exceeds the native command limit')
    for index, check in enumerate(checks):
        if len(check) != 3:
            continue
        source, answers, interaction = check
        rows = interaction['events'][2]['expect_rows']
        edited = rows[:-1] + ['dbg> TCCpuCheck;', '31', 'dbg> ']
        interaction['events'] = interaction['events'][:-1] + [
            {'text': 'TCCpuCheck;'}, {'key': 'ret'},
            {'expect_rows': edited, 'label': 'saved-and-current-task-callers'},
            {'text': 'G;'},
        ]
        interaction['final_rows'] = edited[:-1] + ['dbg> G;']
        checks[index] = (source, answers, interaction)
    return checks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib', type=int, default=8)
    parser.add_argument('--cycles', type=int, default=1,
                        help='Repeated trap/resume cycles; first warms resource accounting')
    args = parser.parse_args()
    if args.cycles < 1 or args.cycles > 20:
        parser.error('--cycles must be between 1 and 20')
    out = args.out.resolve()
    if out.exists():
        parser.error("Use a fresh output directory")
    out.mkdir(parents=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, disk = sha(Path(__file__)), sha(args.disk)
    report = dict(checker_sha256=checker, disk_sha256=disk, cycles=args.cycles, ram_mib=args.ram_mib,
                  scope='TaskCaller saved IP equals actual post-INT3 PC, saved frame points into caller, default task selection, depth exhaustion and current debugger-stack caller; continuation/register/heap checks across repeated traps. Not original debugger UI equivalence or all task states.')
    dependency = ROOT / 'tools/test-i386-debug-cpu-trap.py'
    report['dependency_sha256'] = sha(dependency)
    try:
        checks = commands(args.cycles)
        #Load declarations as source; keep the actual trap/resume UI assertions.
        definitions = [check[0] for index, check in enumerate(checks[:12]) if index not in (5, 7)]
        source = ('\n'.join(definitions) + '\n').encode()
        (out/'TaskCallerCpu.HC').write_bytes(source)
        image = out/'working.img'
        report['packaging'] = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
            args.disk.resolve(), image, additions={'/Probe/TaskCallerCpu.HC': source})
        checks = [('#include "C:/Probe/TaskCallerCpu.HC"', []), checks[5], checks[7]] + checks[12:]
        checks = json.loads(json.dumps(checks).replace('Source: FL:C:/Console.HC,1',
                                                     'Source: FL:C:/Probe/TaskCallerCpu.HC,3'))
        report['commands'] = checks
        (out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(image, out / 'behavior', cpu='486,-fpu', accel='kvm', ram_mib=args.ram_mib, welcome=True,
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': checks})
        if sha(dependency) != report['dependency_sha256']:
            raise ValueError('CPU fixture changed during caller qualification')
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
