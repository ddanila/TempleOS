#!/usr/bin/env python3
"""Check independent renderer cancellation before owner/code or document retirement."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [('#include "/Kernel/I386/PublicUser.HH"', []),
 ('CDoc *rt_doc;CTask *rt_owner,*rt_worker,*rt_deleter;I64 rt_stage,rt_mode,rt_before,rt_error;Bool '
  'rt_ready,rt_returned,rt_live,rt_independent,rt_auto,rt_deleted,rt_caught;',
  []),
 ('U8 *RTTag(CDoc *d,CDocEntry *e,CTask '
  '*t){rt_live=TaskValidate(rt_owner)&&d->win_task==rt_owner&&d->owning_task==Fs;rt_stage=1;if(rt_mode==6)DocDel(d);if(rt_mode==7)return '
  'StrNew("alive",t);while(TRUE)Yield;return NULL;}',
  []),
 ('U0 RTDraw(CDC *dc){DocRecalc(rt_doc,RECALCt_TO_SCRN);}', []),
 ('U0 RTWorker(U8 '
  "*data){try{NativeGraphicsPresent(&RTDraw);rt_returned=TRUE;}catch{rt_error=Fs->except_ch;if(rt_mode==6&&rt_error=='DocBusy'){rt_caught=TRUE;Fs->catch_except=TRUE;}}}",
  []),
 ('U0 RTEntry(U8 *(*tag)(CDoc *d,CDocEntry *e,CTask *t)){CDocEntry '
  '*e=CAlloc(sizeof(CDocEntry),rt_doc->mem_task);e->type=DOCT_TEXT;e->de_flags=DOCEF_TAG|DOCEF_TAG_CB;e->tag=StrNew("keep",rt_doc->mem_task);e->tag_cb=tag;DocInsEntry(rt_doc,e);}',
  []),
 ('U0 RTConfigure(U8 *(*tag)(CDoc *d,CDocEntry *e,CTask '
  '*t)){rt_doc->win_task=Fs;Fs->display_doc=rt_doc;rt_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;RTEntry(tag);rt_ready=TRUE;}',
  []),
 ('U0 RTOwnerWait(){while(!rt_stage)Yield;if(!(rt_mode&1))Exit;while(TRUE)Yield;}', []),
 ('U0 RTOwner(U8 *(*tag)(CDoc *d,CDocEntry *e,CTask '
  '*t)){if(rt_mode&4)rt_doc=DocNew("SharedRender.DD",adam_task);else '
  'rt_doc=DocPut;RTConfigure(tag);RTOwnerWait;}',
  []),
 ('U0 RTBare(U8 *data){rt_doc=DocNew("BareRender.DD");RTConfigure(&RTTag);Fs->put_doc=rt_doc;RTOwnerWait;}',
  []),
 ('U0 RTTurn(){I64 i;for(i=0;i<128;i++)Yield;}', []),
 ('U8 *rt_code="U8 *(*rt_fn)(CDoc *a,CDocEntry *b,CTask *c)=0x%X;\\nU8 *RTLocal(CDoc *d,CDocEntry *e,CTask '
  '*t){return (*rt_fn)(d,e,t);}\\nU0(*rt_start)(U8 *tag)=0x%X;\\n(*rt_start)(&RTLocal);\\n";',
  []),
 ('CTask *RTLaunch(){return User(rt_code,&RTTag,&RTOwner);}', []),
 ('U0 RTReset(I64 '
  'mode){FlushMsgs;rt_before=Fs->data_heap->used_u8s;rt_mode=mode;rt_stage=rt_error=0;rt_ready=rt_returned=rt_live=rt_auto=rt_deleted=rt_caught=FALSE;}',
  []),
 ('U0 RTStartWorker(){rt_worker=Spawn(&RTWorker,NULL,"Independent '
  'renderer",-1,Fs,16384);rt_independent=rt_worker->parent_task==Fs&&Fs!=rt_owner;while(!rt_stage)Yield;}',
  []),
 ('U0 RTStart(I64 mode){RTReset(mode);if(mode&2)rt_owner=Spawn(&RTBare,NULL,"Bare owner",-1,Fs,8192);else '
  'rt_owner=RTLaunch;while(!rt_ready)Yield;RTStartWorker;}',
  []),
 ('U0 '
  'RTObserve(){if(rt_mode&1)Kill(rt_owner,FALSE,FALSE);RTTurn;rt_auto=!TaskValidate(rt_owner)&&!TaskValidate(rt_worker);if(!rt_auto)Kill(rt_worker,TRUE,FALSE);while(TaskValidate(rt_owner))Yield;RTTurn;FlushMsgs;}',
  []),
 ('I64 RTState(){I64 '
  'm=0;if(rt_stage==1&&rt_live&&rt_independent)m|=1;if(rt_auto)m|=2;if(!TaskValidate(rt_worker)&&!rt_returned&&!rt_error)m|=4;if(rt_mode&4)DocDel(rt_doc);if(Fs->data_heap->used_u8s==rt_before)m|=8;return '
  'm;}',
  []),
 ('I64 RTRetry(I64 '
  'm){if(NativeGraphicsPresent())m|=16;if(NativeTextBasePresent())m|=32;NativeTextBaseRestore;return m;}',
  []),
 ('I64 RTRun(I64 mode){RTStart(mode);RTObserve;return RTRetry(RTState);}', []),
 ('RTRun(0);', ['63']),
 ('RTRun(1);', ['63']),
 ('RTRun(2);', ['63']),
 ('RTRun(3);', ['63']),
 ('RTRun(4);', ['63']),
 ('RTRun(5);', ['63']),
 ('U0 RTDelete(U8 *data){DocDel(rt_doc);rt_deleted=TRUE;}', []),
 ('U0 RTDocSetup(I64 '
  'mode){RTReset(mode);rt_owner=Fs;rt_doc=DocNew("RetireDoc.DD");RTEntry(&RTTag);rt_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;RTStartWorker;}',
  []),
 ('I64 RTDeleteRun(){I64 '
  'm=0;RTDocSetup(8);if(rt_stage&&rt_live)m|=1;rt_deleter=Spawn(&RTDelete,NULL,"Document '
  'deleter",-1,Fs,8192);RTTurn;if(rt_deleted&&!TaskValidate(rt_worker))m|=2;else '
  'Kill(rt_worker,TRUE,FALSE);return m;}',
  []),
 ('I64 RTDeleteFinish(I64 '
  'm){while(TaskValidate(rt_deleter))Yield;RTTurn;FlushMsgs;if(rt_deleted&&!rt_returned&&!rt_error)m|=4;if(Fs->data_heap->used_u8s==rt_before)m|=8;return '
  'RTRetry(m);}',
  []),
 ('RTDeleteFinish(RTDeleteRun);', ['63']),
 ('I64 '
  'RTSelf(){RTDocSetup(6);while(TaskValidate(rt_worker))Yield;RTTurn;FlushMsgs;if(!rt_caught||rt_returned||!rt_doc->doc_signature||rt_doc->owning_task)return '
  '0;rt_mode=7;DocRecalc(rt_doc,RECALCt_TO_SCRN);return 1;}',
  []),
 ('I64 RTSelfFinish(){I64 m=RTSelf;if(m&& !StrCmp(rt_doc->head.next(CDocEntry '
  '*)->tag,"alive"))m|=2;DocDel(rt_doc);if(Fs->data_heap->used_u8s==rt_before)m|=4;return m;}',
  []),
 ('RTSelfFinish;', ['7']),
 ('6*7;', ['42'])]


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
    report = dict(result='running', scope='Independent renderer preserves worker Fs: terminal/bare/shared-window owner Exit/kill, owner-compiled callback, explicit document deletion and self-delete rejection, parent recovery and frame reuse; not scheduled refresh or arbitrary stored pointers',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
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
