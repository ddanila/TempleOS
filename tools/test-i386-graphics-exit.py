#!/usr/bin/env python3
"""Check graphics draw/final Exit and interleaved document/frame termination cleanup."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('CDoc *fx_outer,*fx_inner;CTask *fx_task;I64 fx_case,fx_called,fx_before,fx_base;Bool fx_returned;U0 (*fx_draw)(CDC *dc);U0 (*fx_old_final)(CDC *dc);', []),
    ('U8 *FXInnerTag(CDoc *d,CDocEntry *e,CTask *t){fx_called++;Exit;return NULL;}', []),
    ('U0 FXRenderInner(CDC *dc){DocRecalc(fx_inner,RECALCt_TO_SCRN);}', []),
    ('U8 *FXOuterTag(CDoc *d,CDocEntry *e,CTask *t){if(fx_case==4)NativeGraphicsPresent(&FXRenderInner);else if(fx_case==3)NativeGraphicsPresent(fx_draw);else{fx_called++;Exit;}return StrNew("unexpected",t);}', []),
    ('U0 FXDraw(CDC *dc){if(fx_case==2)DocRecalc(fx_outer,RECALCt_TO_SCRN);else{fx_called++;Exit;}}', []),
    ('U0 FXFinal(CDC *dc){fx_called++;Exit;}', []),
    ('U0 FXEntry(CDoc *d,Bool inner){CDocEntry *e=CAlloc(sizeof(CDocEntry));e->type=DOCT_TEXT;e->de_flags=DOCEF_TAG|DOCEF_TAG_CB;e->tag=StrNew("keep");if(inner)e->tag_cb=&FXInnerTag;else e->tag_cb=&FXOuterTag;DocInsEntry(d,e);}', []),
    ('CDoc *FXDoc(Bool inner){CDoc *d=DocNew("GraphicsExit.DD");d->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;FXEntry(d,inner);return d;}', []),
    ('U0 FXDocs(I64 mode){fx_outer=fx_inner=NULL;if(mode>=2)fx_outer=FXDoc(FALSE);if(mode==4)fx_inner=FXDoc(TRUE);}', []),
    ('U0 FXPrepare(I64 mode){FlushMsgs;fx_before=Fs->data_heap->used_u8s;fx_case=mode;fx_called=0;fx_returned=FALSE;FXDocs(mode);fx_base=Fs->data_heap->used_u8s;fx_draw=&FXDraw;fx_old_final=gr.fp_final_scrn_update;if(mode==1)gr.fp_final_scrn_update=&FXFinal;}', []),
    ('U0 FXWorker(U8 *d){if(fx_case>=3)DocRecalc(fx_outer,RECALCt_TO_SCRN);else if(fx_case==1)NativeGraphicsPresent;else NativeGraphicsPresent(fx_draw);fx_returned=TRUE;}', []),
    ('U0 FXStart(){fx_task=Spawn(&FXWorker,NULL,"Graphics exit",-1,Fs,16384);}', []),
    ('U0 FXWait(){I64 i;while(TaskValidate(fx_task))Yield;for(i=0;i<8;i++)Yield;FlushMsgs;}', []),
    ('Bool FXDocOK(CDoc *d){return !d||!d->owning_task&&!Bt(&d->locked_flags,DOClf_LOCKED)&&!StrCmp(d->head.next(CDocEntry *)->tag,"keep");}', []),
    ('Bool FXState(){return FXDocOK(fx_outer)&&FXDocOK(fx_inner);}', []),
    ('I64 FXFinish(){I64 m=0;gr.fp_final_scrn_update=fx_old_final;if(fx_called==1&&!fx_returned)m|=1;if(NativeGraphicsPresent())m|=2;NativeTextBaseRestore;if(FXState)m|=4;if(Fs->data_heap->used_u8s==fx_base)m|=8;return m;}', []),
    ('I64 FXRelease(I64 m){if(!FXState)return m;DocDel(fx_inner);DocDel(fx_outer);if(Fs->data_heap->used_u8s==fx_before)m|=16;return m;}', []),
    ('I64 FXRun(I64 mode){FXPrepare(mode);FXStart;FXWait;return FXRelease(FXFinish);}', []),
    ('FXRun(0);', ['31']),
    ('FXRun(1);', ['31']),
    ('FXRun(2);', ['31']),
    ('FXRun(3);', ['31']),
    ('FXRun(4);', ['31']),
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
    report = dict(result='running', scope='Child draw/final callbacks exit; frame-to-document, document-to-frame and document/frame/document exits; callback entry, no post-return execution, presentation reuse, retained tags and exact parent heap recovery; not owner exit or scheduled refresh',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['30'],
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
