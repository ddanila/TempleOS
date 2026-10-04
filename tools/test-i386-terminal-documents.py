#!/usr/bin/env python3
"""Two live DolDoc editors across terminals with persisted-byte verification."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    original = runpy.run_path(str(ROOT / 'tools/test-i386-terminals.py'))['commands']()
    prefix = original[:9]
    root = ['TempleOS i386', 'HolyC console', '']
    root_busy = root[:]
    for source, answers in prefix:
        typed = '> ' + source
        root_busy += [typed[i:i+80] for i in range(0, len(typed)+1, 80)] + answers
    root_busy += ['> TermRun;', '']
    one = root[:2] + ['Task: One', '', '> ']
    two = root[:2] + ['Task: Two', '', '> ']
    cursor = bytes([0xDB]).decode('cp437')
    def editor(name, text='', saved=False):
        return ['TempleOS i386', 'DolDoc editor' + (' - Saved' if saved else ''),
                'C:/' + name + '.DD', '', text + cursor]
    events = []
    current = one
    def type_text(text):
        for start in range(0, len(text), 4):
            end = min(start + 4, len(text))
            events.extend([{'text': text[start:end]},
                           {'expect_rows': current[:-1] + [current[-1] + text[:end]],
                            'label': 'typing-' + str(len(events))}])
    def enter(text, rows, label):
        nonlocal current
        type_text(text)
        events.extend([{'key': 'ret'}, {'expect_rows': rows, 'label': label}])
        current = rows
    def action(event, rows, label):
        nonlocal current
        events.extend([event, {'expect_rows': rows, 'label': label}])
        current = rows
    for name, heading in [('One', one)]:
        source = 'CDoc *d=DocNew("C:/' + name + '.DD",Fs);'
        enter(source, heading[:-1] + ['> ' + source, '> '], 'one-document')
    enter('DocEd(d);', editor('One'), 'one-editor')
    action({'text': 'one'}, editor('One', 'one'), 'one-edit')
    action({'ctrl_key': 's'}, editor('One', 'one', True), 'one-save')
    action({'hotkey': 'focus-next'}, two, 'two-focus')
    source = 'CDoc *d=DocNew("C:/Two.DD",Fs);'
    enter(source, two[:-1] + ['> ' + source, '> '], 'two-document')
    enter('DocEd(d);', editor('Two'), 'two-editor')
    action({'text': 'two'}, editor('Two', 'two'), 'two-edit')
    action({'ctrl_key': 's'}, editor('Two', 'two', True), 'two-save')
    action({'hotkey': 'focus-next'}, root_busy[-60:], 'root-focus')
    action({'hotkey': 'focus-next'}, editor('One', 'one', True), 'one-editor-restored')
    action({'text': '!'}, editor('One', 'one!'), 'one-revise')
    action({'ctrl_key': 's'}, editor('One', 'one!', True), 'one-resave')
    one_console = one[:-1] + ['1', '> ']
    action({'key': 'esc'}, one_console, 'one-console-title')
    enter('DocDel(d);TermFinish;', editor('Two', 'two', True), 'one-exit')
    action({'text': '?'}, editor('Two', 'two?'), 'two-revise')
    action({'ctrl_key': 's'}, editor('Two', 'two?', True), 'two-resave')
    two_console = two[:-1] + ['1', '> ']
    action({'key': 'esc'}, two_console, 'two-console-title')
    type_text('DocDel(d);TermFinish;')
    return prefix + [('TermRun;', ['1'], {
        'begin': 'TERMINAL TEST enter\n', 'initial_rows': one,
        'events': events, 'final_rows': two_console[:-1] + ['> DocDel(d);TermFinish;'],
        'exit_key': 'ret', 'end': 'TERMINAL TEST return\n', 'preserve_history': True,
    }), ('6*7;', ['42'])]


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
                  scope='Two concurrent text DolDoc sessions, focus isolation, editing/save, terminal identity restoration, exit and independent saved bytes; not sprites, mouse, restart or all private resources')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(session, out / 'behavior', cpu='486,-fpu', snapshot=False,
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands()})
        files = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents']
        expected = {'/One.DD': b'one!\x05', '/Two.DD': b'two?\x05'}
        actual = files(session, set(expected))
        if actual != expected:
            raise ValueError('Saved documents differ from independently expected bytes')
        report['saved_bytes'] = {name: data.hex() for name, data in actual.items()}
        report['session_sha256'] = sha(session)
        if sha(helper) != helper_hash:
            raise ValueError('Terminal fixture helper changed during execution')
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
