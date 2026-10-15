#!/usr/bin/env python3
"""Require cooperative derived-control lock waiting and cancellation isolation."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('#include "/Kernel/I386/PublicUser.HH"', []),
    ('CCtrl *cw_ctrl;CTask *cw_owner,*cw_holder,*cw_waiter;I64 cw_before,cw_calls;Bool cw_release,cw_entered,cw_waiting,cw_first_done,cw_second_done,cw_irq;', []),
    ('U0 CWTurn(){I64 i;for(i=0;i<32;i++)Yield;}', []),
    ('U0 CWUpdate(CCtrl *c){if(Fs==cw_holder){cw_irq=!(GetRFlags&0x200);cw_entered=TRUE;while(!cw_release)Yield;}else if(Fs==cw_waiter)cw_calls++;}', []),
    ('U0 CWFirst(U8 *data){TaskDerivedValsUpdate(cw_owner,FALSE);cw_first_done=TRUE;}', []),
    ('U0 CWSecond(U8 *data){cw_waiting=TRUE;TaskDerivedValsUpdate(cw_owner,FALSE);cw_second_done=TRUE;}', []),
    ('U0 CWReset(){FlushMsgs;cw_before=Fs->data_heap->used_u8s;cw_owner=Fs;cw_calls=0;cw_release=cw_entered=cw_waiting=cw_first_done=cw_second_done=cw_irq=FALSE;cw_ctrl=CAlloc(sizeof(CCtrl));}', []),
    ('U0 CWAttach(){cw_ctrl->type=CTRLT_GENERIC;cw_ctrl->win_task=Fs;cw_ctrl->update_derived_vals=&CWUpdate;QueIns(cw_ctrl,Fs->last_ctrl);cw_holder=Spawn(&CWFirst,NULL,"Derived holder",-1,Fs,8192);while(!cw_entered)Yield;}', []),
    ('I64 CWWait(){I64 m=0;if(cw_irq&&Bt(&Fs->task_flags,TASKf_TASK_LOCK))m|=1;cw_waiter=Spawn(&CWSecond,NULL,"Derived waiter",-1,Fs,8192);while(!cw_waiting)Yield;CWTurn;if(!cw_calls&&!cw_second_done)m|=2;return m;}', []),
    ('I64 CWCancel(I64 m){Kill(cw_waiter,TRUE,FALSE);if(!TaskValidate(cw_waiter)&&TaskValidate(cw_holder)&&Bt(&Fs->task_flags,TASKf_TASK_LOCK))m|=4;return m;}', []),
    ('I64 CWRelease(I64 m,Bool cancel){cw_release=TRUE;while(TaskValidate(cw_holder)||TaskValidate(cw_waiter))Yield;CWTurn;if(!cancel&&cw_calls==1&&cw_second_done)m|=4;if(cw_first_done&&!Bt(&Fs->task_flags,TASKf_TASK_LOCK))m|=8;return m;}', []),
    ('I64 CWFinish(I64 m){QueRem(cw_ctrl);Free(cw_ctrl);FlushMsgs;if(Fs->data_heap->used_u8s==cw_before)m|=16;if(NativeGraphicsPresent()&&NativeTextBasePresent())m|=32;NativeTextBaseRestore;return m;}', []),
    ('I64 CWRun(Bool cancel){I64 m;CWReset;CWAttach;m=CWWait;if(cancel)m=CWCancel(m);return CWFinish(CWRelease(m,cancel));}', []),
    ('CWRun(TRUE);', ['63']),
    ('CWRun(FALSE);', ['63']),
    ('6*7;', ['42']),
]
if any(len(command[0])>255 for command in COMMANDS):
    raise ValueError("Contention fixture exceeds native input limit")


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
    report = dict(result='running', scope='Two explicit derived updaters: contended lock yields, canceled waiter does not unlock holder, later waiter completes, exact parent heap and presentation reuse; not full control-list or automatic scheduling qualification',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':True,
                           'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['61'],
                           'command_timeout':30})
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
