#!/usr/bin/env python3
"""QEMU creation shortcuts: User child, VGA focus, HolyC input and retirement."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
DEFINITIONS = [
    'CTask *HkCaller,*HkLast,*HkTask;I64 HkBefore;',
    'U0 HkLog(U8 *s){while(*s)OutU8(0xE9,*s++);}',
    'I64 HkCount(){CTask *end=(&Gs->seth_task->next_child_task)(U8 *)-offset(CTask.next_sibling_task),*c=Gs->seth_task->next_child_task;I64 n=0;while(c&&c!=end&&n<128){n++;c=c->next_sibling_task;}return n;}',
    'U0 HkPrepare(){HkCaller=Fs;HkBefore=HkCount;HkLast=Gs->seth_task->last_child_task;FlushMsgs;}',
    'Bool HkSelect(){HkTask=HkLast->last_sibling_task;TaskWait(HkTask,TRUE);return TaskValidate(HkTask)&&HkTask->parent_task==Gs->seth_task;}',
    'Bool HkWait(){I64 end=cnts.jiffies+3000;while(HkCount==HkBefore&&cnts.jiffies<end)Yield;return HkCount==HkBefore+1&&HkSelect;}',
    'Bool HkCreate(U8 *tag){HkPrepare;HkLog(tag);if(!HkWait)return FALSE;HkLog("HC child\\n");while(TaskValidate(HkTask))Yield;WinFocus(HkCaller);FlushMsgs;HkLog("HC done\\n");return HkCount==HkBefore;}',
    'Bool HkNoCreate(U8 *tag){HkPrepare;HkLog(tag);try{Sleep(400);}catch{Fs->catch_except=TRUE;}FlushMsgs;HkLog("HN done\\n");return HkCount==HkBefore;}',
]


def commands():
    history = ['TempleOS i386', 'HolyC console', '']
    typed = lambda source: [('> ' + source)[i:i+80]
                            for i in range(0, len(source)+3, 80)]
    specs = [(source, []) for source in DEFINITIONS]
    for source in DEFINITIONS:
        history += typed(source)
    child = history[:2] + ['Task: Unnamed Task', '', '> ']
    for key in ('t', 'esc'):
        source = f'HkCreate("HC {key} ready\\n");'
        before = (history + typed(source))[-60:]
        child_value = child[:-1] + ['> 6*7;', '42', '> ']
        exit_rows = child_value[:-1] + ['> Exit;']
        events = [{'mark_log': 'HC child\n'}, {'keys': ['ctrl', 'alt', key]},
                  {'wait_log_after': 'HC child\n'},
                  {'expect_rows': child, 'label': f'{key}-created-focused'},
                  {'text': '6*7;'}, {'key': 'ret'},
                  {'expect_rows': child_value, 'label': f'{key}-child-holyc'},
                  {'text': 'Exit;'}]
        interaction = {'begin': f'HC {key} ready\n', 'end': 'HC done\n',
                       'initial_rows': before, 'events': events,
                       'final_rows': exit_rows, 'exit_key': 'ret',
                       'preserve_history': True}
        specs.append((source, ['1'], interaction))
        history += typed(source) + ['1']
    negatives = [('plain-t', ['t']), ('plain-esc', ['esc']),
                 ('shift-t', ['ctrl', 'alt', 'shift', 't']),
                 ('shift-esc', ['ctrl', 'alt', 'shift', 'esc'])]
    for label, chord in negatives:
        source = f'HkNoCreate("HN {label} ready\\n");'
        before = (history + typed(source))[-60:]
        #Count creation only: a Shift-Esc break can be caught without claiming
        #that the modifier chord has no other original input action.
        interaction = {'begin': f'HN {label} ready\n', 'end': 'HN done\n',
                       'initial_rows': before, 'final_rows': (history + typed(source) + ['1', '> '])[-60:],
                       'events': [{'keys': chord}], 'preserve_history': True}
        specs.append((source, ['1'], interaction))
        history += typed(source) + ['1']
    specs.append(('6*7;', ['42']))
    if any(len(source) > 255 for source, *_ in specs):
        raise ValueError('Creation fixture exceeds the interactive harness limit')
    return specs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, driver, disk = sha(Path(__file__)), sha(ROOT / 'tools/i386-kernel-input.py'), sha(args.disk)
    report = {'result': 'fail', 'checker_sha256': checker, 'driver_sha256': driver,
              'disk_sha256': disk,
              'scope': 'QEMU Ctrl-Alt-T/Esc creation, CPU-root membership, focused VGA terminal, child 6*7 and Exit, child-list retirement; plain/shift no-creation, resumed root; not typematic, exhaustive heaps or full window stacking'}
    try:
        specs = commands()
        report['commands_sha256'] = hashlib.sha256(json.dumps(specs).encode()).hexdigest()
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
            startup_check={'status': 'ok', 'answers': [], 'commands': specs,
                           'command_timeout': 120})
        if sha(Path(__file__)) != checker or sha(ROOT / 'tools/i386-kernel-input.py') != driver:
            raise ValueError('Checker or keyboard driver changed during execution')
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        report['source_disk_unchanged'] = sha(args.disk) == disk
        if not report['source_disk_unchanged']:
            report.update(result='fail', error='Creation check modified its source disk')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
