#!/usr/bin/env python3
"""Require Refresh(0) to wait for an actual held manager frame."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('#include "/Kernel/I386/PublicUser.HH"', []),
    ('CDoc *rp_doc,*rp_saved;CTask *rp_waiter;I64 rp_before,rp_num;Bool rp_inside,rp_release,rp_started,rp_done,rp_kill,rp_restart;U0 (*rp_old_final)(CDC *dc);', []),
    ('U0 RPHold(CDC *dc){if(Fs==sys_winmgr_task){rp_inside=TRUE;while(!rp_release)Yield;if(rp_kill){rp_kill=FALSE;Fs->task_end_cb=NULL;Exit;}}}', []),
    ('U0 RPSync(U8 *data){Fs->put_doc=NULL;rp_started=TRUE;Refresh(0,FALSE);rp_done=TRUE;}', []),
    ('U0 RPSetup(){FlushMsgs;rp_before=Fs->data_heap->used_u8s;rp_inside=rp_release=rp_started=rp_done=FALSE;rp_num=sys_winmgr_task->task_num;rp_old_final=gr.fp_final_scrn_update;rp_saved=Fs->display_doc;rp_doc=DocNew("RefreshFrame.DD");}', []),
    ('U0 RPStart(){rp_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;gr.fp_final_scrn_update=&RPHold;Fs->display_doc=rp_doc;Suspend(sys_winmgr_task,FALSE);while(!rp_inside)Sleep(1);}', []),
    ('I64 RPWait(){I64 m=0,i;if(Bt(&sys_semas[SEMA_REFRESH_IN_PROGRESS],0))m|=1;rp_waiter=Spawn(&RPSync,NULL,"Frame sync",-1,Fs,8192);while(!rp_started)Yield;for(i=0;i<128;i++)Yield;if(!rp_done&&Bt(&rp_waiter->task_flags,TASKf_IDLE))m|=2;return m;}', []),
    ('U0 RPSupervise(){I64 n;while(sys_winmgr_task==adam_task||sys_winmgr_task->task_num==rp_num)Sleep(1);n=winmgr.updates;while(winmgr.updates<=n)Sleep(1);}', []),
    ('I64 RPRelease(I64 m){rp_release=TRUE;while(TaskValidate(rp_waiter))Yield;if(rp_restart)RPSupervise;if(rp_done)m|=4;if(!Bt(&sys_semas[SEMA_REFRESH_IN_PROGRESS],0))m|=8;Suspend(sys_winmgr_task,TRUE);return m;}', []),
    ('I64 RPFinish(I64 m){gr.fp_final_scrn_update=rp_old_final;Fs->display_doc=rp_saved;DocDel(rp_doc);FlushMsgs;if(Fs->data_heap->used_u8s==rp_before)m|=16;if(NativeGraphicsPresent()&&NativeTextBasePresent())m|=32;NativeTextBaseRestore;return m;}', []),
    ('I64 RPFrame(Bool restart=FALSE){RPSetup;rp_restart=rp_kill=restart;RPStart;return RPFinish(RPRelease(RPWait));}', []),
    ('RPFrame;', ['63']),
    ('RPFrame(TRUE);', ['63']),
    ('6*7;', ['42']),
]
if any(len(command[0])>255 for command in COMMANDS):
    raise ValueError("Refresh frame fixture exceeds native input limit")


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
    report = dict(result='running', scope='Actual manager final-screen callback held under in-progress state; independent zero-count waiter blocks until frame release, exact parent heap and presentation retry; not all raw/debug transitions or full desktop',
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
