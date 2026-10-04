#!/usr/bin/env python3
"""Deliver Ctrl-Alt-C to a focused spawned HolyC loop and recover console input."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    definitions = [
        'U0 KeyLog(U8 *s){while(*s)OutU8(0xE9,*s++);}',
        'I64 KeyBreakResult=0;',
        'U0 KeyBreakWorker(U8 *data){sys_focus_task=Fs;KeyLog("KEY BREAK ready\\n");try{while(1){}}catch{KeyBreakResult=Fs->except_ch==\'Break\';Fs->catch_except=TRUE;}sys_focus_task=Fs->parent_task;}',
        'Bool KeyBreak(){CTask *t=Spawn(&KeyBreakWorker,0,"KeyBreak",-1,Fs,8192);if(!t)return FALSE;while(!KeyBreakResult)Yield;KeyLog("KEY BREAK done\\n");return KeyBreakResult==1&&sys_focus_task==Fs;}',
    ]
    history = ['TempleOS i386', 'HolyC console', '']
    def typed(source):
        text = '> ' + source
        return [text[index:index+80] for index in range(0,len(text)+1,80)]
    for source in definitions:
        history += typed(source)
    call = 'KeyBreak;'
    before = (history + typed(call))[-60:]
    after = (history + typed(call) + ['1', '> '])[-60:]
    interaction = {'begin': 'KEY BREAK ready\n', 'end': 'KEY BREAK done\n',
                   'initial_rows': before, 'final_rows': after,
                   'preserve_history': True, 'events': [{'hotkey': 'break'}]}
    return [(source, []) for source in definitions] + [(call, ['1'], interaction), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    disk_hash, checker = sha(args.disk), sha(Path(__file__))
    report = {'disk_sha256': disk_hash, 'checker_sha256': checker,
              'scope': 'Ctrl-Alt-C reaches focused spawned HolyC task, caught Break, restored console focus and arithmetic; not all cancellation/wait paths'}
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands()})
        if sha(Path(__file__)) != checker:
            raise ValueError('Keyboard checker changed during execution')
        if sha(args.disk) != disk_hash:
            raise ValueError('Keyboard checker modified the input disk')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['source_disk_unchanged'] = sha(args.disk) == disk_hash
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
