#!/usr/bin/env python3
"""Check forced Exit from single and nested document render callbacks."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('#include "/Kernel/I386/PublicUser.HH"', []),
    ('CDoc *ex_outer,*ex_inner;CDocEntry *ex_a,*ex_b;CTask *ex_task;I64 ex_mode,ex_before,ex_base;Bool ex_nested,ex_terminal=FALSE;', []),
    ('U8 *EXInner(CDoc *d,CDocEntry *e,CTask *t){if(ex_mode)Exit;return StrNew("inner",t);}', []),
    ('U8 *EXOuter(CDoc *d,CDocEntry *e,CTask *t){if(ex_nested)DocRecalc(ex_inner,RECALCt_TO_SCRN);else if(ex_mode)Exit;return StrNew("outer",t);}', []),
    ('U0 EXEntry(CDoc *d,Bool inner){CDocEntry *e=CAlloc(sizeof(CDocEntry));e->type=DOCT_TEXT;e->de_flags=DOCEF_TAG|DOCEF_TAG_CB;e->tag=StrNew("keep");if(inner){ex_b=e;e->tag_cb=&EXInner;}else{ex_a=e;e->tag_cb=&EXOuter;}DocInsEntry(d,e);}', []),
    ('CDoc *EXDoc(Bool inner){CDoc *d=DocNew("ExitScope.DD");d->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;EXEntry(d,inner);return d;}', []),
    ('U0 EXWorker(U8 *d){DocRecalc(ex_outer,RECALCt_TO_SCRN);}', []),
    ('U0 EXPrepare(Bool nested){FlushMsgs;ex_before=Fs->data_heap->used_u8s;ex_mode=1;ex_nested=nested;ex_inner=NULL;ex_outer=EXDoc(FALSE);if(nested)ex_inner=EXDoc(TRUE);ex_base=Fs->data_heap->used_u8s;}', []),
    ('U0 EXStart(){if(ex_terminal)ex_task=User("DocRecalc(*(0x%X)(CDoc **),2);\\n",&ex_outer);else ex_task=Spawn(&EXWorker,NULL,"Render exit",-1,Fs,8192);}', []),
    ('U0 EXWait(){I64 i;while(TaskValidate(ex_task))Yield;for(i=0;i<8;i++)Yield;FlushMsgs;}', []),
    ('I64 EXState(){I64 m=0;if(!Bt(&ex_outer->locked_flags,DOClf_LOCKED)&&(!ex_inner||!Bt(&ex_inner->locked_flags,DOClf_LOCKED)))m|=1;if(!ex_outer->owning_task&&(!ex_inner||!ex_inner->owning_task))m|=2;return m;}', []),
    ('I64 EXRead(){I64 m=EXState;if(!StrCmp(ex_a->tag,"keep")&&(!ex_inner||!StrCmp(ex_b->tag,"keep")))m|=4;if(Fs->data_heap->used_u8s==ex_base)m|=8;return m;}', []),
    ('Bool EXRetry(){ex_mode=0;DocRecalc(ex_outer,RECALCt_TO_SCRN);return !StrCmp(ex_a->tag,"outer")&&(!ex_inner||!StrCmp(ex_b->tag,"inner"))&&EXState()==3;}', []),
    ('I64 EXFinish(){I64 m=EXRead;if(m!=15)return m;if(!EXRetry)return -2;DocDel(ex_inner);DocDel(ex_outer);if(Fs->data_heap->used_u8s==ex_before)m|=16;return m;}', []),
    ('I64 EXRun(Bool nested){EXPrepare(nested);EXStart;EXWait;return EXFinish;}', []),
    ('I64 EXUserRun(){I64 m;ex_terminal=TRUE;m=EXRun(TRUE);ex_terminal=FALSE;return m;}', []),
    ('EXRun(FALSE);', ['31']),
    ('EXRun(TRUE);', ['31']),
    ('EXUserRun;', ['31']),
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
    report = dict(result='running', scope='Child and terminal tasks exit from single/nested TO_SCRN tag callbacks: parent-owned tags, released doc locks/aliases, exact parent heap, retry/deletion; not owner exit or all frame-worker lifecycle',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',), 'rejected_answers':['4'],
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
