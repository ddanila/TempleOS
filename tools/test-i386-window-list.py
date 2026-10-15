#!/usr/bin/env python3
"""Check live window identity traversal, mutation, cleanup and independent pixels."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('#include "/Kernel/I386/PublicUser.HH"', []),
    ('#include "/Kernel/I386/PublicRaster.HH"', []),
    ('CTask *wv_a,*wv_b,*wv_new,*wv_focus,*wv_worker;I64 wv_mode,wv_order,wv_ca,wv_cb,wv_cn,wv_before;Bool wv_ok,wv_caught;', []),
    ('U0 (*wv_draw)(CTask *t,CDC *dc);', []),
    ('U0 WVLog(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
    ('U0 WVHold(U8 *data){while(TRUE)Yield;}', []),
    ('U0 WVConfigure(CTask *t,Bool right){t->display_flags=1<<DISPLAYf_SHOW|1<<DISPLAYf_NO_BORDER;t->win_inhibit=WIF_SELF_DOC;t->text_attr=0xF0;t->draw_it=wv_draw;WinHorz(right*40,right*40+39,t);WinVert(0,59,t);}', []),
    ('CTask *WVMake(Bool right){CTask *t=Spawn(&WVHold,NULL,"Window",-1,Fs,8192);WVConfigure(t,right);WinToTop(t);return t;}', []),
    ('U0 WVDeleteNext(){Kill(wv_b,TRUE,FALSE);wv_b=NULL;if(wv_mode==3){wv_new=WVMake(TRUE);wv_b=wv_new;}WinZBufUpdate;wv_mode=0;}', []),
    ("U0 WVAction(){if(wv_mode==1||wv_mode==3)WVDeleteNext;else if(wv_mode==2)WinToTop(wv_a);else if(wv_mode==4)throw('ListFail',TRUE);else if(wv_mode==5)Exit;}", []),
    ('U0 WVDraw(CTask *t,CDC *dc){if(Fs==t||dc->win_task!=t||sys_task_being_scrn_updated!=t)wv_ok=FALSE;if(t==wv_a){wv_ca++;wv_order=wv_order*10+1;WVAction;}else{wv_cb++;wv_order=wv_order*10+2;if(t==wv_new)wv_cn++;}}', []),
    ('U0 WVPaint(CTask *t,CDC *dc){WVDraw(t,dc);if(t==wv_a)dc->color=4;else dc->color=1;GrRect(dc,0,0,320,480);}', []),
    ('U0 WVReset(){wv_order=wv_ca=wv_cb=wv_cn=0;wv_ok=TRUE;}', []),
    ('U0 WVSetup(I64 mode){FlushMsgs;wv_before=Fs->data_heap->used_u8s;wv_focus=sys_focus_task;wv_new=NULL;wv_mode=mode;wv_draw=&WVDraw;WVReset;wv_a=WVMake(FALSE);wv_b=WVMake(TRUE);sys_focus_task=wv_focus;}', []),
    ('U0 WVTurn(){I64 i;for(i=0;i<32;i++)Yield;FlushMsgs;}', []),
    ('I64 WVFinish(I64 m){if(wv_b)Kill(wv_b,TRUE,FALSE);Kill(wv_a,TRUE,FALSE);WVTurn;sys_focus_task=wv_focus;if(Fs->data_heap->used_u8s==wv_before)m|=8;if(NativeGraphicsPresent())m|=16;if(NativeTextBasePresent())m|=32;NativeTextBaseRestore;return m;}', []),
    ('Bool WVNormal(I64 expected=12){return wv_ok&&wv_order==expected&&wv_ca==1&&wv_cb==1&&!sys_task_being_scrn_updated;}', []),
    ('I64 WVReorder(){I64 m=0;WVSetup(2);if(NativeWindowPresent())m|=1;if(WVNormal)m|=2;wv_mode=0;WVReset;if(NativeWindowPresent()&&WVNormal(21))m|=4;return WVFinish(m);}', []),
    ('WVReorder;', ['63']),
    ('U0 WVCoverRaise(){Bool old=LBts(&Fs->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);WinToTop(Fs);LBEqu(&Fs->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP,old);}', []),
    ('I64 WVCover(){I64 m=0;WVSetup(0);WVCoverRaise;WVReset;if(NativeWindowPresent())m|=1;if(wv_ok&&!wv_ca&&!wv_cb)m|=2;WinToTop(wv_a);WinToTop(wv_b);WVReset;if(NativeWindowPresent()&&WVNormal)m|=4;return WVFinish(m);}', []),
    ('WVCover;', ['63']),
    ('I64 WVJoin(){I64 m=0;WVSetup(3);if(NativeWindowPresent())m|=1;if(wv_ok&&wv_ca==1&&!wv_cb&&TaskValidate(wv_new))m|=2;WVReset;if(NativeWindowPresent()&&WVNormal&&wv_cn==1)m|=4;return WVFinish(m);}', []),
    ('WVJoin;', ['63']),
    ("U0 WVTry(){try{NativeWindowPresent;}catch{if(Fs->except_ch=='ListFail'){wv_caught=TRUE;Fs->catch_except=TRUE;}}}", []),
    ('I64 WVFault(){I64 m=0,base;WVSetup(4);base=Fs->data_heap->used_u8s;wv_caught=FALSE;WVTry;if(wv_caught)m|=1;if(Fs->data_heap->used_u8s==base&&!sys_task_being_scrn_updated)m|=2;wv_mode=0;WVReset;if(NativeWindowPresent()&&WVNormal)m|=4;return WVFinish(m);}', []),
    ('WVFault;', ['63']),
    ('U0 WVExitWorker(U8 *data){NativeWindowPresent;}', []),
    ('U0 WVExitStart(){WVSetup(5);wv_worker=Spawn(&WVExitWorker,NULL,"Window presenter",-1,Fs,16384);while(TaskValidate(wv_worker))Yield;WVTurn;}', []),
    ('I64 WVExit(){I64 m=0;WVExitStart;if(wv_ca==1&&wv_ok)m|=1;if(!sys_task_being_scrn_updated)m|=2;wv_mode=0;WVReset;if(NativeWindowPresent()&&WVNormal)m|=4;return WVFinish(m);}', []),
    ('WVExit;', ['63']),
    ('I64 WVFirst(){I64 m=0;WVSetup(0);wv_a->draw_it=wv_b->draw_it=&WVPaint;TextRect(0,79,0,59,0xF000);if(NativeWindowPresent())m|=1;if(WVNormal)m|=2;return m;}', []),
    ('I64 WVSecond(I64 m){wv_mode=1;WVReset;if(NativeWindowPresent()&&wv_ok&&wv_ca==1&&!wv_cb&&!wv_b)m|=4;return m;}', []),
    ('I64 WVView(){I64 m=WVFirst;WVLog("WINDOW LIST first\\n");GetKey;m=WVSecond(m);WVLog("WINDOW LIST second\\n");GetKey;m=WVFinish(m);WVLog("WINDOW LIST end\\n");return m;}', []),
]
rows = [' '*80]*60
first = {(y,x):4 if x<40 else 1 for y in range(60) for x in range(80)}
second = {(y,x):4 if x<40 else 15 for y in range(60) for x in range(80)}
COMMANDS += [('WVView;', ['63'], {
    'begin':'WINDOW LIST first\n','initial_rows':rows,'initial_backgrounds':first,
    'events':[{'key':'spc'},{'wait_log':'WINDOW LIST second\n'}],
    'final_rows':rows,'final_backgrounds':second,'preserve_history':True,
    'exit_key':'esc','end':'WINDOW LIST end\n'}), ('6*7;', ['42'])]
if any(len(entry[0])>255 for entry in COMMANDS):
    raise ValueError('Window-list fixture exceeds the native input limit')


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
    parser.add_argument('--naive-control', action='store_true', help='Use a deliberately unsafe live-pointer traversal to test the oracle')
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if args.naive_control:
        commands = [(entry[0].replace('NativeWindowPresent', 'WVNaivePresent'), *entry[1:]) for entry in commands]
        definitions = [
            ('U0 WVNaiveDraw(CDC *dc){CTask *t=sys_winmgr_task;do{if(TaskValidate(t)&&Bt(&t->display_flags,DISPLAYf_SHOW)&&Bt(gr.win_uncovered_bitmap,t->win_z_num))GrUpdateTaskWin(t);t=t->next_task;}while(t!=sys_winmgr_task);}', []),
            ('Bool WVNaivePresent(){return NativeGraphicsPresent(&WVNaiveDraw);}', []),
        ]
        commands[1:1] = definitions
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, ROOT/'Kernel/FontStd.HC', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Explicit window-ring presentation: independent split-frame pixels, task deletion/reordering/joining across yielding callbacks and cleanup/retry; not scheduled refresh or full window-manager qualification',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib, traversal='naive-control' if args.naive_control else 'native')
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',),
                           'rejected_answers':['61'], 'command_timeout':120})
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
