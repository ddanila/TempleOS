#!/usr/bin/env python3
"""Kill one of two paused CPU trap contexts and preserve the survivor."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    prefix = runpy.run_path(str(ROOT / 'tools/test-i386-terminals.py'))['commands']()[:9]
    prefix += [('U0 ConcurrentTrap(){asm { INT3 NOP }}', []),
               ('Bool TermKill(){if(!Kill(TermOne))return FALSE;TermDone++;return !TermHas(TermOne);}', [])]
    one = ['TempleOS i386', 'HolyC console', 'Task: One', '', '> ']
    two = ['TempleOS i386', 'HolyC console', 'Task: Two', '', '> ']
    debug = ['TempleOS i386', 'HolyC debugger', '', 'Exception: BreakPt',
             'Function: ConcurrentTrap', 'Source: FL:C:/Console.HC,1', 'dbg> ']
    events, current = [], one
    def enter(text, rows, label):
        nonlocal current
        for start in range(0, len(text), 4):
            end = min(start+4, len(text))
            events.extend([{'text': text[start:end]},
                           {'expect_rows': current[:-1]+[current[-1]+text[:end]],
                            'label': label+'-typing-'+str(end)}])
        events.extend([{'key': 'ret'}, {'expect_rows': rows, 'label': label}])
        current = rows
    enter('ConcurrentTrap;', debug, 'first-paused-cpu-trap')
    events.extend([{'hotkey': 'focus-next'}, {'expect_rows': two, 'label': 'second-focus'}])
    current = two
    enter('ConcurrentTrap;', debug, 'second-paused-cpu-trap')
    killed = debug[:-1]+['dbg> TermKill;', '1', 'dbg> ']
    enter('TermKill;', killed, 'first-paused-task-killed')
    alive = killed[:-1]+['dbg> IsDbgMode;', '1', 'dbg> ']
    enter('IsDbgMode;', alive, 'surviving-session-retains-mode')
    alive = alive[:-1]+['dbg> 6*7;', '42', 'dbg> ']
    enter('6*7;', alive, 'surviving-debugger-expression')
    two_return = two[:-1]+['> ConcurrentTrap;', '> ']
    enter('G;', two_return, 'surviving-task-resumed')
    two_return = two_return[:-1]+['> IsDbgMode;', '0', '> ']
    enter('IsDbgMode;', two_return, 'last-session-restores-mode')
    text = 'TermFinish;'
    for start in range(0, len(text), 4):
        end = min(start+4, len(text))
        events.extend([{'text': text[start:end]},
                       {'expect_rows': current[:-1]+[current[-1]+text[:end]],
                        'label': 'exit-typing-'+str(end)}])
    return prefix + [('TermRun;', ['1'], {
        'begin': 'TERMINAL TEST enter\n', 'initial_rows': one, 'events': events,
        'final_rows': current[:-1]+['> TermFinish;'], 'exit_key': 'ret',
        'end': 'TERMINAL TEST return\n', 'preserve_history': True,
    }), ('IsDbgMode;', ['0']), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, disk = sha(Path(__file__)), sha(args.disk)
    dependency = ROOT / 'tools/test-i386-terminals.py'
    report = dict(checker_sha256=checker, disk_sha256=disk,
                  dependency_sha256=sha(dependency),
                  scope='Two simultaneously paused INT3 contexts: kill first, survivor expression/G, shared mode lifetime and parent heap recovery; not all private resources or other-task controls')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands()})
        if sha(dependency) != report['dependency_sha256']:
            raise ValueError('Terminal fixture changed during qualification')
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
