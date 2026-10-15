#!/usr/bin/env python3
"""Check native Refresh interrupted waits, forced Exit and document retirement."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('#include "/Kernel/I386/PublicUser.HH"', []),
    ('CDoc *rw_doc;CTask *rw_worker,*rw_owner;I64 rw_mode,rw_before,rw_observed;Bool rw_ready,rw_caught,rw_returned;', []),
    ("U0 RWAbort(){throw('RfStop',TRUE);}", []),
    ('U0 RWObserve(){rw_observed=Bt(&Fs->task_flags,TASKf_IDLE)|Bt(&rw_doc->flags,DOCf_DO_FULL_REFRESH)<<1;}', []),
    ('U0 RWOwner(U8 *data){rw_doc=DocNew("OwnedRefresh.DD");LBtr(&rw_doc->flags,DOCf_DO_FULL_REFRESH);rw_ready=TRUE;while(TRUE)Yield;}', []),
    ("U0 RWWaiter(U8 *data){Fs->put_doc=rw_doc;if(rw_mode!=1)Fs->task_end_cb=&RWAbort;try{Refresh(2);rw_returned=TRUE;}catch{if(Fs->except_ch=='RfStop'){Fs->catch_except=TRUE;rw_caught=TRUE;RWObserve;}}Fs->put_doc=NULL;}", []),
    ('U0 RWReset(I64 mode){FlushMsgs;rw_before=Fs->data_heap->used_u8s;rw_mode=mode;rw_observed=-1;rw_ready=rw_caught=rw_returned=FALSE;rw_owner=NULL;}', []),
    ('U0 RWDocument(){if(rw_mode==3){rw_owner=Spawn(&RWOwner,NULL,"Refresh doc owner",-1,Fs,8192);while(!rw_ready)Yield;}else{rw_doc=DocNew("RefreshWait.DD");LBtr(&rw_doc->flags,DOCf_DO_FULL_REFRESH);}}', []),
    ('U0 RWStart(){RWDocument;rw_worker=Spawn(&RWWaiter,NULL,"Refresh waiter",-1,Fs,8192);while(!Bt(&rw_worker->task_flags,TASKf_IDLE)||!Bt(&rw_doc->flags,DOCf_DO_FULL_REFRESH))Yield;}', []),
    ('U0 RWStop(){if(rw_mode==2)DocDel(rw_doc);else if(rw_mode==3)Kill(rw_owner,TRUE,FALSE);else Kill(rw_worker,TRUE,FALSE);while(TaskValidate(rw_worker))Yield;if(rw_mode==1)rw_observed=Bt(&rw_doc->flags,DOCf_DO_FULL_REFRESH)<<1;}', []),
    ('I64 RWState(){I64 m=1;if(rw_observed==0)m|=2;if(!TaskValidate(rw_worker)&&!rw_returned&&(rw_caught||rw_mode==1))m|=4;return m;}', []),
    ('I64 RWFinish(I64 m){if(rw_mode<2)DocDel(rw_doc);FlushMsgs;if(Fs->data_heap->used_u8s==rw_before)m|=8;if(NativeGraphicsPresent())m|=16;if(NativeTextBasePresent())m|=32;NativeTextBaseRestore;return m;}', []),
    ('I64 RWRun(I64 mode){RWReset(mode);RWStart;RWStop;return RWFinish(RWState);}', []),
    ('RWRun(0);', ['63']),
    ('RWRun(1);', ['63']),
    ('RWRun(2);', ['63']),
    ('RWRun(3);', ['63']),
    ('6*7;', ['42']),
]
if any(len(command[0])>255 for command in COMMANDS):
    raise ValueError("Refresh wait-state fixture exceeds native input limit")


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
    report = dict(result='running', scope='Paused-manager Refresh waiter: recovered abort, forced Exit, DocDel and document owner retirement restore temporary flags before freeing memory; exact parent heap and frame reuse; not normal cadence or full desktop',
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
