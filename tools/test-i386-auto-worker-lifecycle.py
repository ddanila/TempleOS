#!/usr/bin/env python3
"""Require normal-boot WinMgr cancellation recovery and kernel-root restart."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('#include "/Kernel/I386/PublicUser.HH"', []),
    ('CDoc *aw_doc,*aw_saved;CTask *aw_worker;I64 aw_before,aw_stage,aw_mode,aw_seen,aw_old_num;Bool aw_context;', []),
    ('U8 *AWTag(CDoc *d,CDocEntry *e,CTask *t){aw_stage++;aw_context=Fs==sys_winmgr_task&&Fs!=d->win_task&&d->owning_task==Fs;aw_seen=Fs->task_num;if(aw_mode==1)while(TRUE)Yield;if(aw_mode==3){aw_mode=0;Fs->task_end_cb=NULL;Exit;}return StrNew("A",t);}', []),
    ('U0 AWEntry(){CDocEntry *e=CAlloc(sizeof(CDocEntry));e->type=DOCT_TEXT;e->de_flags=DOCEF_TAG|DOCEF_TAG_CB;e->tag=StrNew("keep");e->tag_cb=&AWTag;DocInsEntry(aw_doc,e);}', []),
    ('U0 AWSetup(I64 mode){FlushMsgs;aw_before=Fs->data_heap->used_u8s;aw_saved=Fs->display_doc;aw_worker=sys_winmgr_task;aw_old_num=aw_worker->task_num;aw_mode=mode;aw_stage=aw_seen=0;aw_context=FALSE;aw_doc=DocNew("AutomaticLifetime.DD");}', []),
    ('U0 AWSelect(){aw_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;AWEntry;Fs->display_doc=aw_doc;while(!aw_stage)Sleep(1);}', []),
    ('U0 AWRelease(){Fs->display_doc=aw_saved;DocDel(aw_doc);aw_doc=NULL;}', []),
    ('I64 AWFinish(I64 m){if(Fs->data_heap->used_u8s==aw_before)m|=8;if(Fs->display_doc==aw_saved&&!sys_task_being_scrn_updated)m|=16;if(NativeGraphicsPresent()&&NativeTextBasePresent())m|=32;NativeTextBaseRestore;return m;}', []),
    ('I64 AWCancel(){I64 m=0;AWSetup(1);if(aw_worker!=adam_task&&!Kill(aw_worker,FALSE,FALSE))m|=1;AWSelect;if(aw_context&&aw_seen==aw_old_num)m|=2;AWRelease;if(TaskValidate(aw_worker)&&sys_winmgr_task==aw_worker)m|=4;return AWFinish(m);}', []),
    ('AWCancel;', ['63']),
    ('U0 AWWaitNew(){while(!TaskValidate(sys_winmgr_task)||sys_winmgr_task==adam_task||sys_winmgr_task->task_num==aw_old_num||aw_seen!=sys_winmgr_task->task_num)Sleep(1);}', []),
    ('I64 AWRestart(){I64 m=0;AWSetup(3);if(aw_worker!=adam_task&&!Kill(aw_worker,FALSE,FALSE))m|=1;AWSelect;AWWaitNew;if(aw_context&&aw_stage>=2)m|=2;if(sys_winmgr_task->task_num!=aw_old_num)m|=4;AWRelease;return AWFinish(m);}', []),
    ('AWRestart;', ['63']),
    ('6*7;', ['42']),
]
if any(len(command[0])>255 for command in COMMANDS):
    raise ValueError('Automatic worker fixture exceeds the native input limit')


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
    report = dict(result='running', scope='Normal-boot managed WinMgr: protected public Kill, actual callback Fs, owner-driven render cancellation, actual worker death/restart, exact parent heap and presentation reuse; not full desktop qualification',
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
