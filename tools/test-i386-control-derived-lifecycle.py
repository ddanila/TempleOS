#!/usr/bin/env python3
"""Check derived-control scope cleanup on return, exceptions, Exit and owner retirement."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('#include "/Kernel/I386/PublicUser.HH"', []),
    ('CCtrl *dl_control;CTask *dl_owner,*dl_worker;I64 dl_mode,dl_stage,dl_before;Bool dl_ready,dl_live,dl_irq,dl_returned,dl_caught;', []),
    ('U0 DLTurn(){I64 i;for(i=0;i<128;i++)Yield;}', []),
    ("U0 DLUpdate(CCtrl *c){dl_live=Fs==dl_worker&&Fs!=c->win_task&&TaskValidate(dl_owner);dl_irq=!(GetRFlags&0x200);dl_stage=1;if(dl_mode==1)throw('DerFail',TRUE);if(dl_mode==2)Exit;if(dl_mode>=3)while(TRUE)Yield;}", []),
    ('U0 DLDetach(){QueRem(dl_control);}', []),
    ('U0 DLOwner(U8 *data){CCtrl *c=dl_control;c->type=CTRLT_GENERIC;c->win_task=Fs;c->update_derived_vals=&DLUpdate;QueIns(c,Fs->last_ctrl);Fs->task_end_cb=&DLDetach;dl_ready=TRUE;while(!dl_stage||dl_mode!=4)Yield;}', []),
    ("U0 DLWorker(U8 *data){try{TaskDerivedValsUpdate(dl_owner,FALSE);dl_returned=TRUE;}catch{if(Fs->except_ch=='DerFail'){dl_caught=TRUE;Fs->catch_except=TRUE;}}}", []),
    ('U0 DLStart(I64 mode){FlushMsgs;dl_before=Fs->data_heap->used_u8s;dl_mode=mode;dl_stage=0;dl_ready=dl_live=dl_irq=dl_returned=dl_caught=FALSE;dl_control=CAlloc(sizeof(CCtrl));dl_owner=Spawn(&DLOwner,NULL,"Derived owner",-1,Fs,8192);while(!dl_ready)Yield;}', []),
    ('U0 DLBegin(){dl_worker=Spawn(&DLWorker,NULL,"Derived worker",-1,Fs,8192);while(!dl_stage)Yield;if(dl_mode==3)Kill(dl_worker,TRUE,FALSE);if(dl_mode==5)Kill(dl_owner,FALSE,FALSE);DLTurn;}', []),
    ('I64 DLState(){I64 m=0;if(dl_live&&dl_irq)m|=1;if(!TaskValidate(dl_owner)||!Bt(&dl_owner->task_flags,TASKf_TASK_LOCK))m|=2;if(!TaskValidate(dl_worker))m|=4;return m;}', []),
    ('Bool DLFlow(){if(!dl_mode)return dl_returned&&!dl_caught;if(dl_mode==1)return !dl_returned&&dl_caught;return !dl_returned&&!dl_caught;}', []),
    ('I64 DLClean(I64 m){if(DLFlow)m|=8;if(TaskValidate(dl_worker))Kill(dl_worker,TRUE,FALSE);if(TaskValidate(dl_owner)){LBtr(&dl_owner->task_flags,TASKf_TASK_LOCK);Kill(dl_owner,TRUE,FALSE);}DLTurn;FlushMsgs;Free(dl_control);return m;}', []),
    ('I64 DLRun(I64 mode){I64 m;DLStart(mode);DLBegin;m=DLClean(DLState);if(Fs->data_heap->used_u8s==dl_before)m|=16;if(NativeGraphicsPresent()&&NativeTextBasePresent())m|=32;NativeTextBaseRestore;return m;}', []),
    ('DLRun(0);', ['63']),
    ('DLRun(1);', ['63']),
    ('DLRun(2);', ['63']),
    ('DLRun(3);', ['63']),
    ('DLRun(4);', ['63']),
    ('DLRun(5);', ['63']),
    ('6*7;', ['42']),
]
if any(len(command[0])>255 for command in COMMANDS):
    raise ValueError("Derived lifecycle fixture exceeds native input limit")


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
    report = dict(result='running', scope='Explicit derived-control update: worker context, IRQ and task lock, return/throw/Exit/kill and owner Exit/kill, exact parent heap and frame reuse; not automatic prepass qualification',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':True,
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
