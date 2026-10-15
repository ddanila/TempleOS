#!/usr/bin/env python3
"""Require whole-window update ordering and task/control cancellation cleanup."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT/'tools/test-i386-render-owner-retire.py'
original = list(runpy.run_path(str(BASE))['COMMANDS'][:20])
extra = [
    ('I64 wu_kind,wu_action,wu_order,wu_left,wu_right,wu_top,wu_bottom;Bool wu_caught;', []),
    ("U0 WUAction(CDC *dc){rt_live=Fs!=rt_owner&&dc->win_task==rt_owner&&sys_task_being_scrn_updated==rt_owner;rt_stage=1;if(!wu_action)while(TRUE)Yield;if(wu_action==2)throw('WinFail',TRUE);if(wu_action==3)Exit;}", []),
    ('U0 WUDraw(CTask *task,CDC *dc){if(wu_kind==2)wu_order=wu_order*10+2;WUAction(dc);}', []),
    ('Bool WUGeometry(){return rt_owner->win_left==wu_left-1&&rt_owner->win_right==wu_right+1&&rt_owner->win_top==wu_top-1&&rt_owner->win_bottom==wu_bottom+1;}', []),
    ('U0 WUCtrl(CDC *dc,CCtrl *c){if(wu_kind==2)wu_order=wu_order*10+3;WUAction(dc);if(!WUGeometry||rt_owner->scroll_x||rt_owner->scroll_y||rt_owner->scroll_z)rt_error=1;}', []),
    ('U0 WUControl(){CCtrl *c=CAlloc(sizeof(CCtrl));c->flags=CTRLF_SHOW|CTRLF_BORDER;c->win_task=Fs;c->draw_it=&WUCtrl;QueIns(c,Fs->last_ctrl);}', []),
    ('U0 WUBounds(){wu_left=Fs->win_left;wu_right=Fs->win_right;wu_top=Fs->win_top;wu_bottom=Fs->win_bottom;Fs->scroll_x=17;Fs->scroll_y=23;Fs->scroll_z=29;}', []),
    ('U0 WUAttach(){Fs->win_inhibit|=0x400;LBtr(&Fs->display_flags,DISPLAYf_NO_BORDER);WUBounds;if(wu_kind!=1)Fs->draw_it=&WUDraw;if(wu_kind)WUControl;}', []),
]
original[3] = ('U0 RTDraw(CDC *dc){GrUpdateTaskWin(rt_owner);}', [])
original[6] = (original[6][0].replace('RTEntry(tag);','RTEntry(tag);WUAttach;'), [])
original[2] = ('U8 *RTTag(CDoc *d,CDocEntry *e,CTask *t){wu_order=wu_order*10+1;return StrNew("alive",t);}', [])
original[4] = ("U0 RTWorker(U8 *data){try{NativeGraphicsPresent(&RTDraw);rt_returned=TRUE;}catch{rt_error=Fs->except_ch;if(rt_error=='WinFail'){wu_caught=TRUE;Fs->catch_except=TRUE;}}}", [])
COMMANDS = original[:2]+extra+original[2:]
COMMANDS += [
    ('wu_kind=0;wu_action=0;RTRun(0);', ['0','0','63']),
    ('RTRun(1);', ['63']),
    ('RTRun(2);', ['63']),
    ('RTRun(3);', ['63']),
    ('wu_kind=1;RTRun(0);', ['1','63']),
    ('RTRun(1);', ['63']),
    ('RTRun(2);', ['63']),
    ('RTRun(3);', ['63']),
    ('U0 WUStart(I64 action){wu_kind=2;wu_action=action;wu_caught=FALSE;wu_order=0;RTReset(3);rt_owner=Spawn(&RTBare,NULL,"Window target",-1,Fs,8192);while(!rt_ready)Yield;}', []),
    ('U0 WURender(){rt_owner->win_inhibit&=~0x400;rt_worker=Spawn(&RTWorker,NULL,"Window renderer",-1,Fs,16384);while(TaskValidate(rt_worker))Yield;RTTurn;FlushMsgs;}', []),
    ('Bool WURestored(){return rt_owner->win_left==wu_left&&rt_owner->win_right==wu_right&&rt_owner->win_top==wu_top&&rt_owner->win_bottom==wu_bottom&&rt_owner->scroll_x==17&&rt_owner->scroll_y==23&&rt_owner->scroll_z==29;}', []),
    ('I64 WUState(){I64 m=0;if(rt_live&&!sys_task_being_scrn_updated)m|=1;if(WURestored)m|=2;if(!rt_doc->owning_task&&!Bt(&rt_doc->locked_flags,DOClf_LOCKED))m|=4;return m;}', []),
    ('I64 WUFinish(I64 m){Kill(rt_owner,TRUE,FALSE);RTTurn;FlushMsgs;if(Fs->data_heap->used_u8s==rt_before)m|=8;return RTRetry(m);}', []),
    ('I64 WURun(){I64 m;WUStart(1);WURender;m=WUState;if(wu_order!=123||!rt_returned||rt_error)return -1;return WUFinish(m);}', []),
    ('WURun;', ['63']),
    ('I64 WUFault(){I64 m;WUStart(2);wu_kind=1;rt_owner->draw_it=NULL;WURender;m=WUState;if(!wu_caught||rt_returned)return -2;return WUFinish(m);}', []),
    ('WUFault;', ['63']),
    ('I64 WUExit(){I64 m;WUStart(3);wu_kind=1;rt_owner->draw_it=NULL;WURender;m=WUState;if(rt_returned||rt_error)return -3;return WUFinish(m);}', []),
    ('WUExit;', ['63']),
    ('6*7;', ['42']),
]
if any(len(source)>255 for source, _ in COMMANDS):
    raise ValueError('Window update fixture exceeds the interactive line limit')


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
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve(), BASE]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Whole-window shared update: task/control owner retirement, original document/draw/control order, caught fault and forced Exit cleanup; not scheduled window manager',
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
