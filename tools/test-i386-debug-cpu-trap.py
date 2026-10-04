#!/usr/bin/env python3
"""Black-box VGA contract for CPU breakpoint entry and continuation."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    heading = ['TempleOS i386', 'HolyC debugger', '',
               'Exception: BreakPt', 'Function: CpuTrapInstruction',
               'Source: FL:C:/Console.HC,1', 'dbg> ']
    return [
        ('I64 CpuTrapStage=0;', []),
        ('U0 CpuTrapLog(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
        ('U0 CpuTrapInstruction(){asm { NOP NOP NOP }}', []),
        ('U8 *CpuTrapBytes=(&CpuTrapInstruction+0)(U64);I64 CpuTrapOffset=0;', []),
        ('Bool CpuTrapFind(){while(CpuTrapOffset<128&&(CpuTrapBytes[CpuTrapOffset]!=0x90||CpuTrapBytes[CpuTrapOffset+1]!=0x90||CpuTrapBytes[CpuTrapOffset+2]!=0x90))CpuTrapOffset++;return CpuTrapOffset<128;}', []),
        ('CpuTrapFind;', ['1']),
        ('U0 CpuTrapPatch(){CpuTrapBytes[CpuTrapOffset]=0xCC;}', []),
        ('CpuTrapPatch;CpuTrapBytes[CpuTrapOffset]==0xCC;', ['1']),
        ('U0 CpuTrapProbe(){CpuTrapStage=1;CpuTrapLog("CPU TRAP enter\\n");CpuTrapInstruction;CpuTrapStage=2;CpuTrapLog("CPU TRAP resumed\\n");}', []),
        ('CpuTrapProbe;', [], {
            'begin': 'CPU TRAP enter\n',
            'initial_rows': heading,
            'events': [
                {'text': 'CpuTrapStage;'}, {'key': 'ret'},
                {'expect_rows': heading[:-1] + ['dbg> CpuTrapStage;', '1', 'dbg> '],
                 'label': 'state'},
                {'text': 'G;'},
            ],
            'final_rows': heading[:-1] + ['dbg> CpuTrapStage;', '1', 'dbg> G;'],
            'exit_key': 'ret',
            'end': 'CPU TRAP resumed\n',
            'preserve_history': True,
        }),
        ('CpuTrapStage;', ['2']),
        ('IsDbgMode;', ['0']),
        ('(GetRFlags&0x300)==0x200;', ['1']),
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
                  scope='Actual INT3 CPU trap, function/source and state inspection, G resumes after INT3, restored debugger mode/IF/TF and shell recovery; not breakpoint installation, stepping or complete register inspection')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands()})
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
