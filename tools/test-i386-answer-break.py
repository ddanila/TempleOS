#!/usr/bin/env python3
"""Check original-derived completed answers and native pending-break cleanup."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]
COMMANDS=[
    ('#include "/Kernel/I386/PublicUser.HH"',[]),
    ("41;throw('Break',TRUE);",['Exception','41']),
    ('Fs->answer==41&&!Fs->new_answer;',['1']),
    ('Fs->task_flags==0;',['1']),
    ('Fs->task_flags|=1<<TASKf_PENDING_BREAK;',['Exception','2048']),
    ('Fs->task_flags==0&&Fs->answer==2048&&!Fs->new_answer;',['1']),
    ('I64 BreakPrivate(){return 99;} Fs->task_flags|=1<<TASKf_PENDING_BREAK;',['Exception','2048']),
    ('BreakPrivate;',['Error: Undefined identifier at ']),
    ('Fs->task_flags==0;',['1']),
    ('U0 LockPending(){Fs->task_flags|=1<<TASKf_BREAK_LOCKED|1<<TASKf_PENDING_BREAK;}',[]),
    ('LockPending;',[]),
    ('Bt(&Fs->task_flags,TASKf_BREAK_LOCKED)&&Bt(&Fs->task_flags,TASKf_PENDING_BREAK);',['1']),
    ('Fs->task_flags&=~(1<<TASKf_BREAK_LOCKED);',['Exception','2048']),
    ('Fs->task_flags==0&&Fs->answer==2048&&!Fs->new_answer;',['1']),
    ('6*7;',['42']),
]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path);parser.add_argument('--reference',type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True);args=parser.parse_args()
    source=args.disk.resolve();ref=args.reference.resolve();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    reference=json.loads((ref/'result.json').read_text())
    if reference.get('result')!='pass' or not reference.get('inputs_unchanged') or len(reference.get('records',[]))!=4:
        raise ValueError('Passing original break reference required')
    paths=[source,ref/'result.json',Path(__file__).resolve(),ROOT/'tools/i386-kernel-input.py']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins={str(p):sha(p) for p in paths}
    out.mkdir(parents=True);report=dict(result='fail',input_sha256=pins,commands=COMMANDS,
        scope='Completed answers through direct/pending/locked breaks, consumed task state and interrupted publication, exact pixels at 8 MiB KVM 486 without FPU/live WinMgr. Native immediate pending-break checkpoint and Exception display differ from original; not whole C4 qualification.')
    try:
        run=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior']=run(source,out/'qemu',snapshot=True,ram_mib=8,cpu='486,-fpu',accel='kvm',
            qmp_stdio=True,welcome=True,keep_window_manager=True,
            startup_check={'status':'ok','answers':[],'commands':COMMANDS,'pause_window_manager':False})
        report['result']='pass'
    except Exception as exc:
        report['error']=str(exc);raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Break answer workflow failed')


if __name__=='__main__':main()
