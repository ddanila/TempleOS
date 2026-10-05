#!/usr/bin/env python3
"""Repeat independent concurrent CPU debugger sessions and heap recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles):
    import copy
    base = runpy.run_path(str(ROOT / 'tools/test-i386-debug-concurrent-traps.py'))['commands']()
    index = next(i for i, item in enumerate(base) if item[0] == 'TermRun;')
    result = base[:index]+[('U0 ConcurrentReset(){TermDone=0;}', [])]
    for _ in range(cycles):
        result += [('ConcurrentReset;', [])]+copy.deepcopy(base[index:])
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--cycles', type=int, default=5)
    args = parser.parse_args()
    if not 1 <= args.cycles <= 20:
        parser.error('cycles must be between 1 and 20')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, disk = sha(Path(__file__)), sha(args.disk)
    dependency = ROOT / 'tools/test-i386-debug-concurrent-traps.py'
    terminal = ROOT / 'tools/test-i386-terminals.py'
    report = dict(checker_sha256=checker, disk_sha256=disk,
                  dependency_sha256=sha(dependency), terminal_sha256=sha(terminal), cycles=args.cycles,
                  scope='Two simultaneously paused INT3 contexts: focus, expression, independent G, shared mode lifetime and parent heap recovery; not other-task G/S or all nested exceptions')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands(args.cycles)})
        if sha(terminal) != report['terminal_sha256']:
            raise ValueError('Terminal fixture changed during qualification')
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
