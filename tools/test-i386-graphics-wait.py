#!/usr/bin/env python3
"""Check cooperative presenter contention, recursive refusal and waiter/holder cancellation."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('CDoc *rw_a,*rw_b;CTask *rw_holder,*rw_waiter;I64 rw_stage,rw_mode,rw_before,rw_base;Bool rw_owner_returned,rw_entered,rw_done,rw_result,rw_recursive,rw_blocked,rw_cancelled;', []),
    ('U8 *RWChildTag(CDoc *d,CDocEntry *e,CTask *t){rw_stage=1;while(TRUE)Yield;return NULL;}', []),
    ('U0 RWDraw(CDC *dc){rw_recursive=!NativeGraphicsPresent()&&!NativeTextBasePresent();DocRecalc(rw_b,RECALCt_TO_SCRN);}', []),
    ('U0 RWHolder(U8 *data){NativeGraphicsPresent(&RWDraw);rw_owner_returned=TRUE;}', []),
    ('U8 *RWParentTag(CDoc *d,CDocEntry *e,CTask *t){rw_holder=Spawn(&RWHolder,NULL,"Frame holder",-1,Fs,16384);while(!rw_stage)Yield;return StrNew("done",t);}', []),
    ('U0 RWEntry(CDoc *d,Bool child){CDocEntry *e=CAlloc(sizeof(CDocEntry));e->type=DOCT_TEXT;e->de_flags=DOCEF_TAG|DOCEF_TAG_CB;e->tag=StrNew("keep");if(child)e->tag_cb=&RWChildTag;else e->tag_cb=&RWParentTag;DocInsEntry(d,e);}', []),
    ('CDoc *RWDoc(Bool child){CDoc *d=DocNew("WaitFrame.DD");d->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;RWEntry(d,child);return d;}', []),
    ('U0 RWWaiter(U8 *data){rw_entered=TRUE;if(rw_mode&1)rw_result=NativeTextBasePresent();else rw_result=NativeGraphicsPresent();rw_done=TRUE;}', []),
    ('U0 RWStartWaiter(){rw_entered=rw_done=rw_result=FALSE;rw_waiter=Spawn(&RWWaiter,NULL,"Frame waiter",-1,Fs,8192);}', []),
    ('U0 RWTurn(){I64 i;for(i=0;i<8;i++)Yield;}', []),
    ('U0 RWObserve(){while(!rw_entered)Yield;RWTurn;rw_blocked=!rw_done&&TaskValidate(rw_waiter)&&TaskValidate(rw_holder);}', []),
    ('U0 RWSetup(I64 mode){FlushMsgs;rw_before=Fs->data_heap->used_u8s;rw_mode=mode;rw_stage=0;rw_owner_returned=rw_recursive=FALSE;rw_cancelled=TRUE;rw_a=RWDoc(FALSE);rw_b=RWDoc(TRUE);rw_base=Fs->data_heap->used_u8s;}', []),
    ('U0 RWBegin(){DocRecalc(rw_a,RECALCt_TO_SCRN);RWStartWaiter;RWObserve;}', []),
    ('U0 RWCancel(){if(rw_mode&2){rw_cancelled=Kill(rw_waiter,TRUE,FALSE)&&!rw_done;RWTurn;RWStartWaiter;RWObserve;}}', []),
    ('Bool RWClear(CDoc *d){return !d->owning_task&&!Bt(&d->locked_flags,DOClf_LOCKED);}', []),
    ('Bool RWTags(){return !StrCmp(rw_a->head.next(CDocEntry *)->tag,"done")&&!StrCmp(rw_b->head.next(CDocEntry *)->tag,"keep");}', []),
    ('I64 RWStop(){I64 m=0;if(rw_stage==1&&rw_recursive&&RWClear(rw_a))m|=1;if(rw_blocked)m|=2;if(Kill(rw_holder,TRUE,FALSE)&&!rw_owner_returned&&rw_cancelled)m|=4;while(TaskValidate(rw_waiter))Yield;RWTurn;FlushMsgs;return m;}', []),
    ('I64 RWResult(I64 m){if(rw_done&&rw_result)m|=8;if(RWClear(rw_a)&&RWClear(rw_b)&&RWTags()&&Fs->data_heap->used_u8s==rw_base)m|=16;if(NativeGraphicsPresent())m|=32;NativeTextBaseRestore;return m;}', []),
    ('I64 RWFree(I64 m){if(!RWClear(rw_a)||!RWClear(rw_b))return m;DocDel(rw_b);DocDel(rw_a);if(Fs->data_heap->used_u8s==rw_before)m|=64;return m;}', []),
    ('I64 RWRun(I64 mode){I64 m;RWSetup(mode);RWBegin;RWCancel;m=RWStop;return RWFree(RWResult(m));}', []),
    ('RWRun(0);', ['127']),
    ('RWRun(1);', ['127']),
    ('RWRun(2);', ['127']),
    ('RWRun(3);', ['127']),
    ('6*7;', ['42']),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Yielding frame/document holder, normal parent scope removal below child scopes, graphics/text waiters, same-task recursive refusal, canceled waiters preserving foreign ownership, holder kill and exact parent recovery; not owner termination or automatic refresh',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['117'],
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
