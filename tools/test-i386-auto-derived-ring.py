#!/usr/bin/env python3
"""Check automatic derived prepass order, hidden targets and callback reordering."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('#include "/Kernel/I386/PublicUser.HH"', []),
    ('CCtrl *dp_ca,*dp_cb,*dp_cm;CTask *dp_a,*dp_b;I64 dp_mode,dp_order,dp_expected,dp_count,dp_ready,dp_before,dp_num;Bool dp_done,dp_context;', []),
    ('U0 DPBottom(CTask *t){CTask *a=sys_winmgr_task;t->last_task->next_task=t->next_task;t->next_task->last_task=t->last_task;t->next_task=a->next_task;t->last_task=a;a->next_task->last_task=t;a->next_task=t;}', []),
    ('U0 DPUpdate(CCtrl *c){if(dp_done)return;dp_context=dp_context&&Fs==sys_winmgr_task&&Fs!=c->win_task&&!(GetRFlags&0x200);dp_order=dp_order*10+c->left;dp_count++;if(dp_count==1&&dp_mode)DPBottom(c->win_task);}', []),
    ('U0 DPMark(CCtrl *c){dp_done=TRUE;}', []),
    ('U0 DPManager(){dp_cm=CAlloc(sizeof(CCtrl));dp_cm->win_task=sys_winmgr_task;dp_cm->update_derived_vals=&DPMark;QueIns(dp_cm,sys_winmgr_task->last_ctrl);}', []),
    ('U0 DPDetachManager(){QueRem(dp_cm);Free(dp_cm);}', []),
    ('U0 DPDetach(){QueRem(Fs->next_ctrl);}', []),
    ('U0 DPOwner(U8 *data){CCtrl *c=data;c->win_task=Fs;QueIns(c,Fs->last_ctrl);Fs->task_end_cb=&DPDetach;dp_ready++;while(TRUE)Yield;}', []),
    ('U0 DPReset(I64 mode){Suspend(sys_winmgr_task,TRUE);FlushMsgs;dp_before=Fs->data_heap->used_u8s;dp_num=sys_winmgr_task->task_num;dp_mode=mode;dp_order=dp_count=dp_ready=0;dp_done=FALSE;dp_context=TRUE;}', []),
    ('U0 DPControls(){dp_ca=CAlloc(sizeof(CCtrl));dp_cb=CAlloc(sizeof(CCtrl));dp_ca->left=1;dp_cb->left=2;dp_ca->update_derived_vals=dp_cb->update_derived_vals=&DPUpdate;}', []),
    ('U0 DPStart(){DPControls;dp_a=Spawn(&DPOwner,dp_ca,"Hidden A",-1,Fs,8192);dp_b=Spawn(&DPOwner,dp_cb,"Hidden B",-1,Fs,8192);while(dp_ready!=2)Yield;}', []),
    ('U0 DPExpected(){CTask *t=sys_winmgr_task->last_task;dp_expected=0;while(t!=sys_winmgr_task){if(t==dp_a)dp_expected=dp_expected*10+1;if(t==dp_b)dp_expected=dp_expected*10+2;t=t->last_task;}}', []),
    ('Bool DPHidden(CTask *t){return !Bt(&t->display_flags,DISPLAYf_SHOW)&&!Bt(&t->task_flags,TASKf_TASK_LOCK);}', []),
    ('I64 DPState(){I64 m=0;if(dp_context)m|=1;if(dp_count==2&&dp_order==dp_expected)m|=2;if(DPHidden(dp_a)&&DPHidden(dp_b))m|=4;return m;}', []),
    ('I64 DPStop(I64 m){DPDetachManager;Kill(dp_a,TRUE,FALSE);Kill(dp_b,TRUE,FALSE);Free(dp_ca);Free(dp_cb);FlushMsgs;if(sys_winmgr_task->task_num==dp_num)m|=8;if(Fs->data_heap->used_u8s==dp_before)m|=16;return m;}', []),
    ('I64 DPRun(I64 mode){I64 m;DPReset(mode);DPStart;DPExpected;DPManager;Suspend(sys_winmgr_task,FALSE);while(!dp_done)Sleep(1);Suspend(sys_winmgr_task,TRUE);m=DPStop(DPState);Suspend(sys_winmgr_task,FALSE);return m;}', []),
    ('I64 DPFrame(I64 m){if(NativeGraphicsPresent()&&NativeTextBasePresent())m|=32;NativeTextBaseRestore;return m;}', []),
    ('DPFrame(DPRun(0));', ['63']),
    ('DPFrame(DPRun(1));', ['63']),
    ('6*7;', ['42']),
]
if any(len(command[0])>255 for command in COMMANDS):
    raise ValueError("Automatic ring fixture exceeds native input limit")


def serializable(value):
    if isinstance(value,dict):
        return {str(key):serializable(item) for key,item in value.items()}
    if isinstance(value,(list,tuple)):
        return [serializable(item) for item in value]
    if isinstance(value,set):
        return [serializable(item) for item in sorted(value)]
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, ROOT/'Kernel/FontStd.HC', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Normal WinMgr automatic hidden-task derived pass: predecessor order survives callback ring reordering, manager context/IRQ, locks, exact parent heap and frame reuse; not arbitrary control-list mutation or full desktop qualification',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':False,
                           'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['61'],
                           'command_timeout':120})
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Native fixture inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':
        raise ValueError(report['error'])


if __name__=='__main__':
    main()
