#!/usr/bin/env python3
"""Check terminal document-owner exit while a linked child renders a yielding tag."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [('#include "/Kernel/I386/PublicUser.HH"', []),
 ('CDoc *ro_doc;CTask *ro_owner,*ro_worker;I64 ro_stage,ro_mode,ro_before;Bool ro_ready,ro_returned,ro_live;',
  []),
 ('U8 *ROTag(CDoc *d,CDocEntry *e,CTask '
  '*t){ro_live=TaskValidate(ro_owner)&&d==ro_owner->display_doc&&d->owning_task==Fs;ro_stage=1;while(TRUE)Yield;return '
  'NULL;}',
  []),
 ('U0 RODraw(CDC *dc){DocRecalc(ro_doc,RECALCt_TO_SCRN);}', []),
 ('U0 ROWorker(U8 *data){NativeGraphicsPresent(&RODraw);ro_returned=TRUE;}', []),
 ('U0 ROEntry(U8 *(*tag)(CDoc *d,CDocEntry *e,CTask *t)){CDocEntry '
  '*e=CAlloc(sizeof(CDocEntry));e->type=DOCT_TEXT;e->de_flags=DOCEF_TAG|DOCEF_TAG_CB;e->tag=StrNew("keep");e->tag_cb=tag;DocInsEntry(ro_doc,e);}',
  []),
 ('U0 ROOwnerWait(){while(!ro_stage)Yield;ro_ready=TRUE;if(!ro_mode)Exit;while(TRUE)Yield;}', []),
 ('U0 ROOwner(U8 *(*tag)(CDoc *d,CDocEntry *e,CTask '
  '*t)){ro_doc=DocPut;ro_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;ROEntry(tag);ro_worker=Spawn(&ROWorker,NULL,"Owned '
  'renderer",-1,Fs,16384);ROOwnerWait;}',
  []),
 ('U0 ROTurn(){I64 i;for(i=0;i<8;i++)Yield;}', []),
 ('U8 *ro_code="U8 *(*ro_fn)(CDoc *a,CDocEntry *b,CTask *c)=0x%X;\\nU8 *ROLocal(CDoc *d,CDocEntry *e,CTask '
  '*t){return (*ro_fn)(d,e,t);}\\nU0(*ro_start)(U8 *tag)=0x%X;\\n(*ro_start)(&ROLocal);\\n";',
  []),
 ('CTask *ROLaunch(){return User(ro_code,&ROTag,&ROOwner);}', []),
 ('U0 ROStart(I64 '
  'mode){FlushMsgs;ro_before=Fs->data_heap->used_u8s;ro_mode=mode;ro_stage=0;ro_ready=ro_returned=ro_live=FALSE;ro_owner=ROLaunch;while(!ro_ready)Yield;}',
  []),
 ('I64 ROStop(){I64 '
  'm=0;if(ro_stage==1&&ro_live)m|=1;if(!ro_mode||Kill(ro_owner,TRUE,FALSE))m|=2;while(TaskValidate(ro_owner))Yield;ROTurn;FlushMsgs;if(!TaskValidate(ro_worker)&&!ro_returned)m|=4;if(Fs->data_heap->used_u8s==ro_before)m|=8;return '
  'm;}',
  []),
 ('I64 RORun(I64 mode){I64 '
  'm;ROStart(mode);m=ROStop;if(NativeGraphicsPresent())m|=16;if(NativeTextBasePresent())m|=32;NativeTextBaseRestore;return '
  'm;}',
  []),
 ('RORun(0);', ['63']),
 ('RORun(1);', ['63']),
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
    report = dict(result='running', scope='Terminal-owned document, linked rendering child yielding in tag callback, owner Exit/external kill, descendant retirement, parent heap recovery and graphics/text reuse; not independent worker ownership or automatic refresh',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
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
