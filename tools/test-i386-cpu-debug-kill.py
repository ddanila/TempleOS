#!/usr/bin/env python3
"""Kill a terminal stopped at a CPU breakpoint, then debug in its survivor."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(single_step=False):
    prefix = runpy.run_path(str(ROOT / 'tools/test-i386-terminals.py'))['commands']()[:9]
    prefix += [('HashFind("Kill",Fs->hash_table,HTT_FUN)!=0;', ['1']),
               ('Bool TermKill(){if(!Kill(TermOne))return FALSE;TermDone++;return !TermHas(TermOne);}', [])]
    one = ['TempleOS i386', 'HolyC console', 'Task: One', '', '> ']
    two = ['TempleOS i386', 'HolyC console', 'Task: Two', '', '> ']
    events, current = [], one
    def enter(text, rows, label):
        nonlocal current
        for start in range(0, len(text), 4):
            end = min(start + 4, len(text))
            events.extend([{'text': text[start:end]},
                           {'expect_rows': current[:-1] + [current[-1] + text[:end]],
                            'label': 'typing-' + str(len(events))}])
        events.extend([{'key': 'ret'}, {'expect_rows': rows, 'label': label}])
        current = rows
    def debugger(name, value, function):
        return ['TempleOS i386', 'HolyC debugger', '', 'Message: ' + name,
                'Value: ' + str(value), 'Function: ' + function, 'dbg> ']
    source = 'U0 DebugVictim(){asm { INT3 NOP NOP }}' if single_step else 'U0 DebugVictim(){asm { INT3 }}'
    enter(source, one[:-1] + ['> ' + source, '> '], 'victim-function')
    enter('DebugVictim;', ['TempleOS i386', 'HolyC debugger', '',
        'Exception: BreakPt', 'Function: DebugVictim',
        'Source: FL:C:/Console.HC,1', 'dbg> '], 'victim-cpu-debugger')
    if single_step:
        enter('S;', ['TempleOS i386', 'HolyC debugger', '',
            'Exception: BreakPt', 'Function: DebugVictim',
            'Source: FL:C:/Console.HC,1', 'dbg> '], 'victim-single-step')
    events.extend([{'hotkey': 'focus-next'}, {'expect_rows': two, 'label': 'survivor-focus'}])
    current = two
    enter('TermKill;', two[:-1] + ['> TermKill;', '1', '> '], 'victim-killed')
    source = 'U0 DebugSurvivor(){Dbg("Survivor",42);}'
    enter(source, current[:-1] + ['> ' + source, '> '], 'survivor-function')
    restored = current[:-1] + ['> DebugSurvivor;', '> ']
    debug = debugger('Survivor', 42, 'DebugSurvivor')
    enter('DebugSurvivor;', debug, 'survivor-debugger')
    enter('6*7;', debug[:-1] + ['dbg> 6*7;', '42', 'dbg> '], 'survivor-expression')
    enter('G;', restored, 'survivor-return')
    text = 'TermFinish;'
    for start in range(0, len(text), 4):
        end = min(start+4, len(text))
        events.extend([{'text': text[start:end]},
                       {'expect_rows': current[:-1] + [current[-1]+text[:end]],
                        'label': 'exit-typing-' + str(end)}])
    return prefix + [('TermRun;', ['1'], {
        'begin': 'TERMINAL TEST enter\n', 'initial_rows': one,
        'events': events, 'final_rows': current[:-1] + ['> TermFinish;'],
        'exit_key': 'ret', 'end': 'TERMINAL TEST return\n', 'preserve_history': True,
    }), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--single-step', action='store_true', help='Kill after S hardware-step reentry')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, disk = sha(Path(__file__)), sha(args.disk)
    report = dict(checker_sha256=checker, disk_sha256=disk, single_step=args.single_step,
                  scope='Kill a terminal at real INT3, then enter Dbg in a survivor, evaluate and G back, exit and recover parent public heap; not all private resources or complete register/step coverage')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands(args.single_step)})
        if sha(Path(__file__)) != checker:
            raise ValueError('Debugger checker changed during execution')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['source_disk_unchanged'] = sha(args.disk) == disk
        if not report['source_disk_unchanged']:
            report.update(result='fail', error='Debugger check modified source disk')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
