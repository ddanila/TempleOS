#!/usr/bin/env python3
"""Check actual WinMgr cancellation and restart inside automatic derived callbacks."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('#include "/Kernel/I386/PublicUser.HH"', []),
    ('CCtrl *al_ctrl;CTask *al_owner;I64 al_mode,al_stage,al_before,al_num,al_calls,al_wm_before;Bool al_ready,al_context;', []),
    ('U0 ALDetach(){QueRem(al_ctrl);}', []),
    ('U0 ALUpdate(CCtrl *c){al_context=al_context&&Fs==sys_winmgr_task&&Fs!=c->win_task&&!(GetRFlags&0x200);al_stage++;if(!al_mode)while(TRUE)Yield;if(al_mode==2){al_mode=1;Fs->task_end_cb=NULL;Exit;}al_calls++;}', []),
    ('U0 ALOwner(U8 *data){al_ctrl->win_task=Fs;QueIns(al_ctrl,Fs->last_ctrl);Fs->task_end_cb=&ALDetach;al_ready=TRUE;while(TRUE)Yield;}', []),
    ('U0 ALCreate(){al_ready=FALSE;al_owner=Spawn(&ALOwner,NULL,"Automatic derived owner",-1,Fs,8192);while(!al_ready)Yield;}', []),
    ('U0 ALMeasure(){al_before=Fs->data_heap->used_u8s;al_wm_before=sys_winmgr_task->data_heap->used_u8s;}', []),
    ('U0 ALReset(I64 mode){Suspend(sys_winmgr_task,TRUE);FlushMsgs;ALMeasure;al_num=sys_winmgr_task->task_num;al_mode=mode;al_stage=al_calls=0;al_context=TRUE;}', []),
    ('U0 ALStart(){al_ctrl=CAlloc(sizeof(CCtrl));al_ctrl->update_derived_vals=&ALUpdate;ALCreate;Suspend(sys_winmgr_task,FALSE);while(!al_stage)Sleep(1);}', []),
    ('I64 ALCancel(){I64 m=0;Kill(al_owner,TRUE,FALSE);if(!TaskValidate(al_owner)&&sys_winmgr_task->task_num==al_num)m|=2;al_mode=1;ALCreate;while(!al_calls)Sleep(1);if(al_stage>=2)m|=4;return m;}', []),
    ('I64 ALRestart(){I64 m=0;while(sys_winmgr_task->task_num==al_num||!al_calls)Sleep(1);if(TaskValidate(sys_winmgr_task))m|=2;if(al_stage>=2)m|=4;return m;}', []),
    ('Bool ALCleanWorker(){return !sys_task_being_scrn_updated&&TaskValidate(sys_winmgr_task)&&sys_winmgr_task->data_heap->used_u8s==al_wm_before;}', []),
    ('I64 ALFinish(I64 m){if(al_context)m|=1;Kill(al_owner,TRUE,FALSE);Free(al_ctrl);FlushMsgs;if(ALCleanWorker)m|=8;if(Fs->data_heap->used_u8s==al_before)m|=16;return m;}', []),
    ('I64 ALRun(I64 mode){I64 m;ALReset(mode);ALStart;if(mode==2)m=ALRestart;else m=ALCancel;m=ALFinish(m);if(NativeGraphicsPresent()&&NativeTextBasePresent())m|=32;NativeTextBaseRestore;return m;}', []),
    ('ALRun(0);', ['63']),
    ('ALRun(2);', ['63']),
    ('6*7;', ['42']),
]
if any(len(command[0])>255 for command in COMMANDS):
    raise ValueError("Automatic derived lifecycle fixture exceeds native input limit")


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
    report = dict(result='running', scope='Automatic hidden-control callback on actual manager: owner retirement cancels a held derived pass, same worker resumes; actual worker Exit creates a new identity and next callback; exact parent and manager heap and presentation reuse; not full desktop or control-list mutation',
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
