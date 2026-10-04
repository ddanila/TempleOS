#!/usr/bin/env python3
"""Inject a QEMU key pair to a focused spawned HolyC task waiting in GetMsg."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    definitions = [
        'U0 KeyLog(U8 *s){while(*s)OutU8(0xE9,*s++);}',
        'Bool KeyEvent(I64 code){I64 a,s;return GetMsg(&a,&s,1<<code)==code&&a==97&&(s&127)==30;}',
        'I64 KeyFocusResult=0;',
        'U0 KeyFocusWorker(U8 *data){sys_focus_task=Fs;KeyLog("KEY FOCUS ready\\n");if(KeyEvent(MSG_KEY_DOWN)&&KeyEvent(MSG_KEY_UP))KeyFocusResult=1;else KeyFocusResult=-1;sys_focus_task=Fs->parent_task;}',
        'Bool KeyFocus(){CTask *old=sys_focus_task,*t;I64 e=cnts.jiffies+10000;t=Spawn(&KeyFocusWorker,0,"KeyFocus",-1,Fs,8192);if(!t)return FALSE;while(!KeyFocusResult&&cnts.jiffies<e)Yield;sys_focus_task=old;KeyLog("KEY FOCUS done\\n");return KeyFocusResult==1;}',
    ]
    history = ['TempleOS i386', 'HolyC console', '']
    def typed(source):
        text = '> ' + source
        return [text[index:index+80] for index in range(0,len(text)+1,80)]
    for source in definitions:
        history += typed(source)
    call = 'KeyFocus;'
    before = (history + typed(call))[-60:]
    after = (history + typed(call) + ['1', '> '])[-60:]
    interaction = {'begin': 'KEY FOCUS ready\n', 'end': 'KEY FOCUS done\n',
                   'initial_rows': before, 'final_rows': after,
                   'preserve_history': True, 'events': [{'key': 'a'}]}
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
              'scope': 'QEMU make/break delivery through public GetMsg, ASCII/scan code, resumed console; focused spawned-child delivery and restoration of console input; not input loss or focused-child break routing'}
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
