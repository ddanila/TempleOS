#!/usr/bin/env python3
"""Kill one of two paused CPU trap contexts and preserve the survivor."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles=5):
    from copy import deepcopy
    prefix=runpy.run_path(str(ROOT/'tools/test-i386-terminals.py'))['commands']()[:9]
    prefix += [('U0 CpuExitTrap(){asm { INT3 NOP }}',[]),('U0 CpuExitReset(){TermDone=0;}',[])]
    one=['TempleOS i386','HolyC console','Task: One','','> ']
    two=['TempleOS i386','HolyC console','Task: Two','','> ']
    debug=['TempleOS i386','HolyC debugger','','Exception: BreakPt','Function: CpuExitTrap','Source: FL:C:/Console.HC,1','dbg> ']
    events=[];current=one
    def enter(text,rows,label):
        nonlocal current
        for start in range(0,len(text),4):
            end=min(start+4,len(text))
            events.extend([{'text':text[start:end]},{'expect_rows':current[:-1]+[current[-1]+text[:end]],'label':label+'-typing-'+str(end)}])
        events.extend([{'key':'ret'},{'expect_rows':rows,'label':label}]);current=rows
    enter('CpuExitTrap;',debug,'cpu-debugger')
    enter('TermFinish;',two,'debugger-self-exit')
    enter('IsDbgMode;',two[:-1]+['> IsDbgMode;','0','> '],'mode-restored')
    enter('6*7;',current[:-1]+['> 6*7;','42','> '],'survivor-expression')
    for start in range(0,len('TermFinish;'),4):
        end=min(start+4,len('TermFinish;'))
        events.extend([{'text':'TermFinish;'[start:end]},{'expect_rows':current[:-1]+[current[-1]+'TermFinish;'[:end]],'label':'survivor-exit-typing-'+str(end)}])
    interaction={'begin':'TERMINAL TEST enter\n','initial_rows':one,'events':events,'final_rows':current[:-1]+['> TermFinish;'],'exit_key':'ret','end':'TERMINAL TEST return\n','preserve_history':True}
    checks=list(prefix)
    for _ in range(cycles):
        checks += [('CpuExitReset;',[]),('TermRun;',['1'],deepcopy(interaction)),('IsDbgMode;',['0']),('6*7;',['42'])]
    return checks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--cycles',type=int,default=5)
    args = parser.parse_args()
    if not 1<=args.cycles<=20:parser.error('--cycles must be between 1 and 20')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    checker, disk = sha(Path(__file__)), sha(args.disk)
    dependency = ROOT / 'tools/test-i386-terminals.py'
    report = dict(checker_sha256=checker, disk_sha256=disk,
                  dependency_sha256=sha(dependency), cycles=args.cycles,
                  scope='Repeated actual INT3 debugger self-exit, task reaping, restored mode, survivor commands and exact parent public heap recovery; not a direct private kernel heap allocation audit')
    try:
        runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status': 'ok', 'answers': [],
                                         'commands': commands(args.cycles)})
        if sha(dependency) != report['dependency_sha256']:
            raise ValueError('Terminal fixture changed during qualification')
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
