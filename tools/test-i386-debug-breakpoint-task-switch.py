#!/usr/bin/env python3
"""Verify task-owned breakpoints on shared code across two terminal contexts."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(both_own=False):
    prefix = runpy.run_path(str(ROOT / 'tools/test-i386-terminals.py'))['commands']()[:9]
    prefix += [('U0 SharedProbe(){asm { NOP NOP NOP }}', []),
               ('U8 *SharedBytes=(&SharedProbe+0)(U64);U8 SharedOriginal=SharedBytes[0];', [])]
    one = ['TempleOS i386', 'HolyC console', 'Task: One', '', '> ']
    two = ['TempleOS i386', 'HolyC console', 'Task: Two', '', '> ']
    events, current = [], one
    def enter(text, rows, label):
        nonlocal current
        for start in range(0,len(text),4):
            end = min(start+4,len(text))
            events.extend([{'text': text[start:end]},
                {'expect_rows': current[:-1] + [current[-1]+text[:end]], 'label': label+'-typing-'+str(end)}])
        events.extend([{'key':'ret'}, {'expect_rows':rows,'label':label}])
        current = rows
    one_set = one[:-1] + ['> BptS(&SharedProbe);','0','> ']
    enter('BptS(&SharedProbe);',one_set,'owner-install')
    enter('TermFocus(TermTwo);',two,'other-focus')
    two_run = two[:-1] + ['> SharedProbe;','> ']
    enter('SharedProbe;',two_run,'other-untrapped')
    if both_own:
        two_run = two_run[:-1] + ['> BptS(&SharedProbe);','0','> ']
        enter('BptS(&SharedProbe);',two_run,'second-owner-install')
    check = 'BptFind(&SharedProbe)!=0&&BptFind(&SharedProbe,TermOne)!=0;' if both_own else 'BptFind(&SharedProbe)==0&&BptFind(&SharedProbe,TermOne)!=0;'
    two_checked = two_run[:-1] + ['> '+check,'1','> ']
    enter(check,two_checked,'separate-record-lists')
    one_back = one_set[:-1] + ['> TermFocus(TermTwo);','> ']
    enter('TermFocus(TermOne);',one_back,'owner-refocus')
    debug = ['TempleOS i386','HolyC debugger','','Exception: BreakPt',
             'Function: SharedProbe','Source: FL:C:/Console.HC,1','dbg> ']
    enter('SharedProbe;',debug,'owner-trap')
    restored = one_back[:-1] + ['> SharedProbe;','> ']
    enter('G2;',restored,'owner-clear-resume')
    two_back = two_checked[:-1] + ['> TermFocus(TermOne);','> ']
    enter('TermFinish;',two_back,'owner-exit')
    if both_own:
        check = 'BptFind(&SharedProbe)!=0;'
        enter(check,two_back[:-1] + ['> '+check,'1','> '],'remaining-owner-record')
        enter('SharedProbe;',debug,'second-owner-trap')
        restored = two_back[:-1] + ['> '+check,'1','> SharedProbe;','> ']
        enter('G2;',restored,'second-owner-clear-resume')
        two_back = current
    check = 'SharedBytes[0]==SharedOriginal&&Fs->bpt_lst==0;'
    enter(check,two_back[:-1] + ['> '+check,'1','> '],'shared-code-restored')
    enter('SharedProbe;',current[:-1] + ['> SharedProbe;','> '],'survivor-untrapped')
    final = current[:-1] + ['> TermFinish;']
    text = 'TermFinish;'
    for start in range(0,len(text),4):
        end=min(start+4,len(text))
        events.extend([{'text':text[start:end]},
            {'expect_rows':current[:-1]+[current[-1]+text[:end]],'label':'exit-typing-'+str(end)}])
    return prefix + [('TermRun;',['1'],{
        'begin':'TERMINAL TEST enter\n','initial_rows':one,'events':events,
        'final_rows':final,'exit_key':'ret','end':'TERMINAL TEST return\n','preserve_history':True,
    }),('6*7;',['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--both-own', action='store_true', help='Both terminals own the same breakpoint address')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, disk = sha(Path(__file__)), sha(args.disk)
    report = dict(checker_sha256=checker, disk_sha256=disk, both_own=args.both_own, 
                  scope='One child owns breakpoint on shared parent code; other child executes untrapped, owner traps/clears, survivor executes restored code; public parent heap recovery. Optional same-address records clear independently and both owners trap sequentially; not simultaneous debugger sessions or full other-task controls')
    try:
        dependency = ROOT / 'tools/test-i386-terminals.py'
        report['dependency_sha256'] = hashlib.sha256(dependency.read_bytes()).hexdigest()
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands(args.both_own)})
        if hashlib.sha256(dependency.read_bytes()).hexdigest() != report['dependency_sha256']:
            raise ValueError('Terminal fixture changed during managed kill test')
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
