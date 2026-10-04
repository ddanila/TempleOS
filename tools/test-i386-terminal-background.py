#!/usr/bin/env python3
"""Compile HolyC in one terminal while another edits and saves a DolDoc document."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    prefix = runpy.run_path(str(ROOT / 'tools/test-i386-terminals.py'))['commands']()[:9]
    prefix += [('I64 BuildCount=0,BuildStop=0,BuildValue=0;', []),
               ('U0 TermCompile(CDoc *d){TermLog("BACKGROUND COMPILE begin\\n");while(!BuildStop){if(!DocExe(d))throw(\'Compile\');BuildCount++;Yield;}DocDel(d);TermFinish;}', [])]
    one = ['TempleOS i386', 'HolyC console', 'Task: One', '', '> ']
    two = ['TempleOS i386', 'HolyC console', 'Task: Two', '', '> ']
    events, current = [], one
    def type_text(text):
        for start in range(0, len(text), 4):
            end = min(start + 4, len(text))
            events.extend([{'text': text[start:end]},
                           {'expect_rows': current[:-1] + [current[-1] + text[:end]],
                            'label': 'typing-' + str(len(events))}])
    def enter(text, answers, label):
        nonlocal current
        type_text(text)
        current = current[:-1] + ['> ' + text] + answers + ['> ']
        events.extend([{'key': 'ret'}, {'expect_rows': current, 'label': label}])
    enter('CDoc *d=DocNew("C:/Background.HC",Fs);', [], 'compiler-document')
    enter('U8 *src="BuildValue=6*7;";while(*src)DocPutKey(d,*src++);', [], 'compiler-source')
    type_text('TermCompile(d);')
    events.extend([{'key': 'ret'}, {'wait_log': 'BACKGROUND COMPILE begin\n'},
                   {'hotkey': 'focus-next'}, {'expect_rows': two, 'label': 'foreground-editor-terminal'}])
    current = two
    enter('BuildCount>0;', ['1'], 'compiler-started')
    enter('I64 seen=BuildCount;', [], 'compiler-progress-before')
    enter('CDoc *d=DocNew("C:/Work.DD",Fs);', [], 'editor-document')
    type_text('DocEd(d);')
    cursor = bytes([0xDB]).decode('cp437')
    editor = ['TempleOS i386', 'DolDoc editor', 'C:/Work.DD', '', cursor]
    events.extend([{'key': 'ret'}, {'expect_rows': editor, 'label': 'editor-open'},
                   {'text': 'work'}, {'expect_rows': editor[:-1] + ['work' + cursor], 'label': 'editor-typed'},
                   {'ctrl_key': 's'},
                   {'expect_rows': [editor[0], 'DolDoc editor - Saved'] + editor[2:-1] + ['work' + cursor], 'label': 'editor-saved'},
                   {'key': 'esc'}])
    current = two[:-1] + ['1', '> ']
    events.append({'expect_rows': current, 'label': 'editor-closed'})
    enter('BuildCount>seen&&BuildValue==42;', ['1'], 'compiler-progress-during-editor')
    enter('BuildStop=1;', ['1'], 'compiler-stop')
    type_text('DocDel(d);TermFinish;')
    result = prefix + [('TermRun;', ['1'], {
        'begin': 'TERMINAL TEST enter\n', 'initial_rows': one,
        'events': events, 'final_rows': current[:-1] + ['> DocDel(d);TermFinish;'],
        'exit_key': 'ret', 'end': 'TERMINAL TEST return\n', 'preserve_history': True,
    }), ('BuildCount>1&&BuildValue==42;', ['1']), ('6*7;', ['42'])]
    if any(len(source)>255 for source, *_ in result):
        raise ValueError('Background fixture exceeds console input limit')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, disk = sha(Path(__file__)), sha(args.disk)
    helper = ROOT / 'tools/test-i386-terminals.py'
    helper_hash = sha(helper)
    session = out / 'session.img'
    if session == args.disk.resolve():
        raise ValueError('Session image would overwrite source')
    shutil.copyfile(args.disk, session)
    report = dict(checker_sha256=checker, disk_sha256=disk, helper_sha256=helper_hash,
                  scope='Repeated background HolyC compilation advances while foreground text DolDoc editing/save remains usable; persisted bytes, retained value and parent public heap recovery; not complete OS rebuild concurrency or all private resources')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(session, out / 'behavior', cpu='486,-fpu', snapshot=False,
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands()})
        files = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents']
        expected = {'/Work.DD': b'work\x05'}
        actual = files(session, set(expected))
        if actual != expected:
            raise ValueError('Saved documents differ from independently expected bytes')
        report['saved_bytes'] = {name: data.hex() for name, data in actual.items()}
        report['session_sha256'] = sha(session)
        if sha(helper) != helper_hash:
            raise ValueError('Terminal fixture helper changed during execution')
        if sha(Path(__file__)) != checker:
            raise ValueError('Background checker changed during execution')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['source_disk_unchanged'] = sha(args.disk) == disk
        if not report['source_disk_unchanged']:
            report.update(result='fail', error='Background check modified source disk')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
