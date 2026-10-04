#!/usr/bin/env python3
"""Black-box VGA contract for original runtime exception/source inspection."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    heading = ['TempleOS i386', 'HolyC debugger', '',
               'Exception: 0', 'Function: ExceptionProbe',
               'Source: FL:C:/Console.HC,1', 'dbg> ']
    return [
        ('HashFind("DbgMode",Fs->hash_table,HTT_FUN)!=0;', ['1']),
        ('I64 ExceptionStage=0;', []),
        ('U0 ExceptionLog(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
        ('U0 ExceptionProbe(){ExceptionStage=1;ExceptionLog("EXCEPTION TEST enter\\n");throw(0,TRUE);ExceptionStage=2;}', []),
        ('DbgMode(TRUE);', ['0']),
        ('ExceptionProbe;', ['Exception'], {
            'begin': 'EXCEPTION TEST enter\n',
            'initial_rows': heading,
            'events': [
                {'text': 'ExceptionStage;'}, {'key': 'ret'},
                {'expect_rows': heading[:-1] + ['dbg> ExceptionStage;', '1', 'dbg> '],
                 'label': 'state'},
                {'text': 'G;'},
            ],
            'final_rows': heading[:-1] + ['dbg> ExceptionStage;', '1', 'dbg> G;'],
            'exit_key': 'ret',
            'end': 'COMMAND ERROR\n',
            'preserve_history': True,
        }),
        ('ExceptionStage;', ['1']),
        ('DbgMode(FALSE);', ['1']),
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
                  scope='Zero-valued thrown exception classified as an exception with function/source, state inspection, G unwind and shell recovery; not registers, stepping or breakpoints')
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
