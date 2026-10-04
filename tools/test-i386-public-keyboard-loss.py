#!/usr/bin/env python3
"""Overflow the hardware queue while its decoder is suspended, then recover input."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    definitions = [
        'U0 KeyLog(U8 *s){while(*s)OutU8(0xE9,*s++);}',
        'CTask *KeyLossWorker(){CTask *r=Fs->parent_task,*h=(&r->next_child_task)(U8 *)-offset(CTask.next_sibling_task),*t;for(t=r->next_child_task;t!=h;t=t->next_sibling_task)if(!StrCmp(t->task_name,"Keyboard"))return t;return NULL;}',
        'Bool KeyLossPrime(){I64 a,s;KeyLog("KEY LOSS prime\\n");return GetMsg(&a,&s,1<<MSG_KEY_DOWN)==MSG_KEY_DOWN&&a==0&&(s&127)==42;}',
        'Bool KeyLoss(){CTask *t=KeyLossWorker;if(!t||!KeyLossPrime)return FALSE;Suspend(t);KeyLog("KEY LOSS ready\\n");Sleep(2000);Suspend(t,FALSE);KeyLog("KEY LOSS done\\n");return TRUE;}',
    ]
    history = ['TempleOS i386', 'HolyC console', '']
    def typed(source):
        text = '> ' + source
        return [text[index:index+80] for index in range(0,len(text)+1,80)]
    for source in definitions:
        history += typed(source)
    call = 'KeyLoss;'
    before = (history + typed(call))[-60:]
    after = (history + typed(call) + ['1', '> ', 'Input reset', '> '])[-60:]
    interaction = {'begin': 'KEY LOSS prime\n', 'end': 'KEY LOSS done\n',
                   'initial_rows': before, 'final_rows': after,
                   'preserve_history': True, 'events': [{'shift_key': 'a'}, {'wait_log': 'KEY LOSS ready\n'}] + [action for _ in range(40) for action in ({'key': 'a'}, {'delay': 0.01})]}
    return [(source, []) for source in definitions] + [(call, ['1', '> ', 'Input reset'], interaction), ('I64 loss_recovered=42;loss_recovered;', ['42'])]


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
              'scope': 'Hardware raw-queue overflow, exactly one console reset, discarded Shift release and recovered typing; not focused-child discontinuity notification'}
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands()})
        resets = (out / 'behavior/debug.log').read_text().count('INPUT RESET\n')
        if resets != 1:
            raise ValueError(f'Expected one input reset, got {resets}')
        report['input_resets'] = resets
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
