#!/usr/bin/env python3
"""Idle Ctrl-Alt-C must preserve a terminal, its definitions and sibling isolation."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    root = ['TempleOS i386', 'HolyC console', '']
    one = root[:2] + ['Task: One', '', '> ']
    two = root[:2] + ['Task: Two', '', '> ']
    definitions = [
        'HashFind("UserCmdLine",Fs->hash_table,HTT_FUN)!=0&&HashFind("WinFocus",Fs->hash_table,HTT_FUN)!=0;',
        'CTask *TermRoot,*TermOne,*TermTwo;I64 TermDone=0,TermBefore;',
        'U0 TermLog(U8 *s){while(*s)OutU8(0xE9,*s++);}',
        'U0 TermFocus(CTask *t){WinFocus(t);}',
        'U0 TermFinish(){TermDone++;Exit;}',
        'Bool TermHas(CTask *t){CTask *e=(&TermRoot->next_child_task)(U8 *)-offset(CTask.next_sibling_task),*c=TermRoot->next_child_task;I64 n=0;while(c&&c!=e&&n++<128){if(c==t)return TRUE;c=c->next_sibling_task;}return FALSE;}',
        'U0 TermSpawn(){TermOne=Spawn(&UserCmdLine,0,"One",-1,Fs,8192);TermTwo=Spawn(&UserCmdLine,0,"Two",-1,Fs,8192);}',
        'Bool TermWait(){while(TermDone!=2||TermHas(TermOne)||TermHas(TermTwo))Yield;FlushMsgs;TermLog("TERMINAL TEST return\\n");return Fs->data_heap->used_u8s==TermBefore;}',
        'Bool TermRun(){TermRoot=Fs;FlushMsgs;TermBefore=Fs->data_heap->used_u8s;TermSpawn;Sleep(100);TermLog("TERMINAL TEST enter\\n");TermFocus(TermOne);return TermWait;}',
    ]
    events = []
    current_rows = one
    def type_text(text, label):
        for start in range(0, len(text), 4):
            end = min(start + 4, len(text))
            events.extend([{'text': text[start:end]},
                           {'expect_rows': current_rows[:-1] + [current_rows[-1] + text[:end]],
                            'label': f'{label}-typing-{end}'}])
    def enter(text, rows, label):
        nonlocal current_rows
        type_text(text, label)
        events.extend([{'key': 'ret'}, {'expect_rows': rows, 'label': label}])
        current_rows = rows
    one1 = one[:-1] + ['> I64 terminal_value=11;', '> ']
    enter('I64 terminal_value=11;', one1, 'one-definition')
    events.append({'hotkey': 'break'})
    one1 = one1[:-1] + ['> ^C', '> Exception', '> ']
    events.append({'expect_rows': one1, 'label': 'idle-break-recovered'})
    enter('terminal_value;', one1[:-1] + ['> terminal_value;', '11', '> '], 'retained-after-break')
    one1 = current_rows
    two0 = two
    enter('TermFocus(TermTwo);', two0, 'two-focus')
    two1 = two[:-1] + ['> HashFind("terminal_value",Fs->hash_table,HTT_GLBL_VAR)!=0;', '0', '> ']
    enter('HashFind("terminal_value",Fs->hash_table,HTT_GLBL_VAR)!=0;', two1, 'two-isolation')
    two2 = two1[:-1] + ['> I64 terminal_value=22;', '> ']
    enter('I64 terminal_value=22;', two2, 'two-definition')
    one2 = one1[:-1] + ['> TermFocus(TermTwo);', '> ']
    enter('TermFocus(TermOne);', one2, 'one-history')
    one3 = one2[:-1] + ['> terminal_value;', '11', '> ']
    enter('terminal_value;', one3, 'one-value')
    two3 = two2[:-1] + ['> TermFocus(TermOne);', '> ']
    enter('TermFinish;', two3, 'one-exit-refocus')
    two4 = two3[:-1] + ['> terminal_value;', '22', '> ']
    enter('terminal_value;', two4, 'two-value')
    type_text('TermFinish;', 'two-exit')
    specs = [(source, ['1'] if i == 0 else []) for i, source in enumerate(definitions)]
    specs += [('TermRun;', ['1'], {
        'begin': 'TERMINAL TEST enter\n', 'initial_rows': one,
        'events': events,
        'final_rows': two4[:-1] + ['> TermFinish;'],
        'exit_key': 'ret', 'end': 'TERMINAL TEST return\n',
        'preserve_history': True,
    }), ('6*7;', ['42'])]
    if any(len(source) > 255 for source, *_ in specs):
        raise ValueError('Terminal fixture exceeds input line limit')
    return specs


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
                  scope='Idle hardware Ctrl-Alt-C recovery in One, retained definition, sibling isolation, focus and exit, exact parent public heap recovery; not active editor/compiler cancellation or all private resources')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands()})
        if sha(Path(__file__)) != checker:
            raise ValueError('Terminal break checker changed during execution')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['source_disk_unchanged'] = sha(args.disk) == disk
        if not report['source_disk_unchanged']:
            report.update(result='fail', error='Terminal break check modified source disk')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
