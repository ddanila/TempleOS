#!/usr/bin/env python3
"""Check formatted popup buffer and request lifetimes across recovered cancellation and Exit."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('CTask *pl_old,*pl_client,*pl_inner,*pl_slot;I64 pl_mode,pl_before,pl_client_before;Bool pl_caught,pl_returned,pl_clean,pl_alive,pl_release,pl_queue_empty,pl_heap_clean;', []),
    ("U0 PLAbort(){throw('PuStop',TRUE);}", []),
    ('U0 PLHold(U8 *data){while(TRUE)Yield;}', []),
    ('U0 PLPrior(){pl_old=Spawn(&PLHold,NULL,"Old popup",-1,Fs,8192);Fs->popup_task=pl_old;}', []),
    ('I64 PLPriorFinish(I64 ok){Fs->popup_task=NULL;if(TaskValidate(pl_old))Kill(pl_old);return ok;}', []),
    ('I64 PLPrevious(Bool retire=FALSE){I64 r,ok;PLPrior;if(retire)r=PopUpPrint("%s","Kill(pl_old);42;");else r=PopUpPrint("42;");ok=r==42;if(retire)ok&=!Fs->popup_task;else ok&=Fs->popup_task==pl_old;return PLPriorFinish(ok);}', []),
    ('U0 PLClientBegin(){pl_client_before=Fs->data_heap->used_u8s;if(pl_mode!=1)Fs->task_end_cb=&PLAbort;}', []),
    ('U0 PLClientDone(){pl_alive=TRUE;if(pl_mode==2)while(!pl_release)Yield;}', []),
    ('U0 PLClient(U8 *d){PLClientBegin;try{PopUpPrint("%s","pl_inner=Fs;while(TRUE)Yield;");pl_returned=TRUE;}catch{if(Fs->except_ch==\'PuStop\'){Fs->catch_except=TRUE;pl_caught=TRUE;pl_clean=!Fs->popup_task;}}PLClientDone;}', []),
    ('U0 PLReset(I64 mode){FlushMsgs;pl_before=Fs->data_heap->used_u8s;pl_mode=mode;pl_caught=pl_returned=pl_clean=FALSE;pl_client=pl_inner=NULL;pl_slot=Fs;pl_alive=pl_release=pl_queue_empty=pl_heap_clean=FALSE;}', []),
    ('U0 PLStart(){pl_client=Spawn(&PLClient,NULL,"Popup caller",-1,Fs,16384);while(!pl_inner)Yield;while(pl_client->popup_task!=pl_inner)Yield;}', []),
    ('Bool PLQueues(){CJobCtrl*c=&pl_client->srv_ctrl;return c->next_done==&c->next_done&&c->next_waiting==&c->next_waiting;}', []),
    ('U0 PLInspect(){while(!pl_alive||TaskValidate(pl_inner))Yield;pl_queue_empty=PLQueues;pl_heap_clean=pl_client->data_heap->used_u8s==pl_client_before;pl_release=TRUE;}', []),
    ('U0 PLStop(){Kill(pl_client,TRUE,FALSE);if(pl_mode==2)PLInspect;while(TaskValidate(pl_client)||TaskValidate(pl_inner))Yield;FlushMsgs;}', []),
    ('I64 PLState(){I64 m=0;if(!pl_returned)m|=1;if(pl_mode!=1&&pl_caught&&pl_clean||pl_mode==1&&!pl_caught)m|=2;if(pl_slot==Fs&&!Fs->popup_task)m|=4;if(Fs->data_heap->used_u8s==pl_before)m|=8;return m;}', []),
    ('I64 PLFinish(I64 m){if(NativeGraphicsPresent())m|=16;if(NativeTextBasePresent())m|=32;NativeTextBaseRestore;return m;}', []),
    ('I64 PLRun(I64 mode){PLReset(mode);PLStart;PLStop;return PLFinish(PLState);}', []),
    ('I64 PLLive(){I64 m=PLRun(2);if(pl_queue_empty)m|=64;if(pl_heap_clean)m|=128;return m;}', []),
    ('PLPrevious;', ['1']),
    ('PLPrevious(TRUE);', ['1']),
    ('PLRun(0);', ['63']),
    ('PLRun(1);', ['63']),
    ('PLLive;', ['255']),
    ('6*7;', ['42']),
]

if any(len(c[0])>255 for c in COMMANDS):
    raise ValueError("Put/display fixture exceeds native input limit")


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
    report = dict(result='running', scope='Formatted popup previous-owner restoration/retirement, recovered caller cancellation and committed kill: both tasks retire, caller state unchanged, caller heap and presentation reusable; live recovered caller must have empty job rings and recovered heap before retirement; not arbitrary output-pointer owner lifetime, child faults or menu UI',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':False,
                           'rejection_prefixes':('INPUT REJECT ',),
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
