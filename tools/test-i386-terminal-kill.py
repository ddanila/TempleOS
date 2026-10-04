#!/usr/bin/env python3
"""Kill a terminal inside DolDoc and verify surviving terminal editing and cleanup."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    prefix = runpy.run_path(str(ROOT / 'tools/test-i386-terminals.py'))['commands']()[:9]
    prefix.append(('HashFind("Kill",Fs->hash_table,HTT_FUN)!=0;', ['1']))
    prefix.append(('Bool TermKill(){if(!Kill(TermOne))return FALSE;TermDone++;return !TermHas(TermOne);}', []))
    one = ['TempleOS i386', 'HolyC console', 'Task: One', '', '> ']
    two = ['TempleOS i386', 'HolyC console', 'Task: Two', '', '> ']
    cursor = bytes([0xDB]).decode('cp437')
    events, current = [], one
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
    def editor(name, body='', saved=False):
        return ['TempleOS i386', 'DolDoc editor' + (' - Saved' if saved else ''),
                'C:/' + name + '.DD', '', body + cursor]
    source = 'CDoc *d=DocNew("C:/Victim.DD",Fs);'
    enter(source, one[:-1] + ['> ' + source, '> '], 'victim-document')
    enter('DocEd(d);', editor('Victim'), 'victim-editor')
    events.extend([{'text': 'lost'}, {'expect_rows': editor('Victim', 'lost'), 'label': 'victim-unsaved'},
                   {'hotkey': 'focus-next'}, {'expect_rows': two, 'label': 'survivor-focus'}])
    current = two
    enter('TermKill;', two[:-1] + ['> TermKill;', '1', '> '], 'victim-killed')
    source = 'CDoc *d=DocNew("C:/Survivor.DD",Fs);'
    enter(source, current[:-1] + ['> ' + source, '> '], 'survivor-document')
    enter('DocEd(d);', editor('Survivor'), 'survivor-editor')
    events.extend([{'text': 'ok'}, {'expect_rows': editor('Survivor', 'ok'), 'label': 'survivor-typed'},
                   {'ctrl_key': 's'}, {'expect_rows': editor('Survivor', 'ok', True), 'label': 'survivor-saved'},
                   {'key': 'esc'}])
    current = two[:-1] + ['1', '> ']
    events.append({'expect_rows': current, 'label': 'survivor-console'})
    type_text('DocDel(d);TermFinish;')
    return prefix + [('TermRun;', ['1'], {
        'begin': 'TERMINAL TEST enter\n', 'initial_rows': one,
        'events': events, 'final_rows': current[:-1] + ['> DocDel(d);TermFinish;'],
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
                  scope='Kill an inactive terminal during text DolDoc editing, child-list removal, surviving editor/save, parent public heap recovery and persisted bytes; not all private resources, mouse/sprites or debugger cancellation')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(session, out / 'behavior', cpu='486,-fpu', snapshot=False,
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands()})
        files = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents']
        expected = {'/Survivor.DD': b'ok\x05'}
        actual = files(session, set(expected))
        if actual != expected:
            raise ValueError('Saved documents differ from independently expected bytes')
        report['saved_bytes'] = {name: data.hex() for name, data in actual.items()}
        report['session_sha256'] = sha(session)
        if sha(helper) != helper_hash:
            raise ValueError('Terminal fixture helper changed during execution')
        if sha(Path(__file__)) != checker:
            raise ValueError('Terminal kill checker changed during execution')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['source_disk_unchanged'] = sha(args.disk) == disk
        if not report['source_disk_unchanged']:
            report.update(result='fail', error='Terminal kill check modified source disk')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
