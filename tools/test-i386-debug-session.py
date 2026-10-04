#!/usr/bin/env python3
"""Black-box VGA contract for explicit Dbg entry, inspection and G return."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    heading = ['TempleOS i386', 'HolyC debugger', '',
               'Message: M7 debug', 'Value: 42', 'Function: DebugProbe', 'dbg> ']
    return [
        ('HashFind("Dbg",Fs->hash_table,HTT_FUN)!=0;', ['1']),
        ('I64 DebugStage=0;', []),
        ('U0 DebugLog(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
        ('U0 DebugProbe(){DebugStage=1;DebugLog("DEBUG TEST enter\\n");Dbg("M7 debug",42);DebugStage=2;DebugLog("DEBUG TEST return\\n");}', []),
        ('DebugProbe;', [], {
            'begin': 'DEBUG TEST enter\n',
            'initial_rows': heading,
            'events': [
                {'text': '6*7;'}, {'key': 'ret'},
                {'expect_rows': heading[:-1] + ['dbg> 6*7;', '42', 'dbg> '],
                 'label': 'expression'},
                {'text': 'G;'},
            ],
            'final_rows': heading[:-1] + ['dbg> 6*7;', '42', 'dbg> G;'],
            'exit_key': 'ret',
            'end': 'DEBUG TEST return\n',
            'preserve_history': True,
        }),
        ('DebugStage;', ['2']),
        ('6*7;', ['42']),
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, disk = sha(Path(__file__)), sha(args.disk)
    report = dict(checker_sha256=checker, disk_sha256=disk,
                  scope='Explicit Dbg message/value/function, nested expression, G continuation and shell recovery; not exception inspection, registers, breakpoints or stepping')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands()})
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
