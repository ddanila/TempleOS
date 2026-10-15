#!/usr/bin/env python3
"""Check automatic window failure isolation, reporting and cleanup."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('CDoc *eh_doc,*eh_saved;I64 eh_before,eh_flags,eh_num,eh_attr;Bool eh_context;', []),
    ('U0 EHLog(U8 *s){while(*s)OutU8(0xE9,*s++);}', []),
    ("U8 *EHFail(CDoc *d,CDocEntry *e,CTask *t){eh_context=Fs==sys_winmgr_task&&Fs!=d->win_task&&d->owning_task==Fs;throw('WndFail',TRUE);return NULL;}", []),
    ('U0 EHEntry(){CDocEntry *e=CAlloc(sizeof(CDocEntry));e->type=DOCT_TEXT;e->de_flags=DOCEF_TAG|DOCEF_TAG_CB;e->tag=StrNew("keep");e->tag_cb=&EHFail;DocInsEntry(eh_doc,e);}', []),
    ('U0 EHSetup(){eh_before=Fs->data_heap->used_u8s;eh_saved=Fs->display_doc;eh_flags=Fs->display_flags;eh_num=sys_winmgr_task->task_num;eh_attr=Fs->text_attr;eh_context=FALSE;eh_doc=DocNew("FailingWindow.DD");}', []),
    ('U0 EHSelect(){eh_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;EHEntry;Fs->text_attr=0xF0;Fs->display_doc=eh_doc;}', []),
    ('U0 EHWait(){while(Bt(&Fs->display_flags,DISPLAYf_SHOW)||sys_winmgr_task->wake_jiffy<cnts.jiffies+1000)Sleep(1);}', []),
    ('I64 EHState(){I64 m=0;if(eh_context)m|=1;if(!Bt(&Fs->display_flags,DISPLAYf_SHOW))m|=2;if(!eh_doc->owning_task&&!Bt(&eh_doc->locked_flags,DOClf_LOCKED)&&!StrCmp(eh_doc->head.next(CDocEntry *)->tag,"keep"))m|=4;return m;}', []),
    ('I64 EHFinish(I64 m){Fs->display_doc=eh_saved;Fs->display_flags=eh_flags;Fs->text_attr=eh_attr;DocDel(eh_doc);if(Fs->data_heap->used_u8s==eh_before)m|=8;if(TaskValidate(sys_winmgr_task)&&sys_winmgr_task->task_num==eh_num)m|=16;return m;}', []),
    ('U0 EHScreen(U8 *s){I64 i;for(i=0;i<60;i++)"\\n";"%s",s;}', []),
    ('I64 EHRun(){I64 m;EHSetup;EHSelect;EHWait;m=EHFinish(EHState);if(NativeGraphicsPresent()&&NativeTextBasePresent())m|=32;NativeTextBaseRestore;EHScreen("Error isolated\\n");EHLog("WM ERROR ready\\n");return m;}', []),
    ('I64 EHView(){I64 m=EHRun;GetKey;EHScreen("TempleOS i386\\nHolyC console\\n\\n");EHLog("WM ERROR end\\n");return m;}', []),
]
COMMANDS += [('EHView;', ['63'], {
    'begin':'WM ERROR ready\n','initial_rows':['']*58+['Error isolated',''],
    'events':[],'final_rows':['']*58+['Error isolated',''],
    'return_rows':['']*55+['TempleOS i386','HolyC console','','63','> '],
    'exit_key':'esc','end':'WM ERROR end\n'}), ('6*7;', ['42'])]
if any(len(command[0])>255 for command in COMMANDS):
    raise ValueError('Automatic error fixture exceeds the native input limit')


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
    report = dict(result='running', scope='Automatic worker callback failure: window hidden, document/heap cleanup, manager survives and error delay/report occur; console reset after observations; not full debugger/error-policy parity',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':False,
                           'rejection_prefixes':('INPUT REJECT ',),
                           'command_timeout':120})
        if 'WINMGR window exception 006C696146646E57 ' not in (out/'qemu/debug.log').read_text():
            raise ValueError('Missing worker error report')
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
