#!/usr/bin/env python3
"""Exercise persistent managed render-worker cancellation and replacement recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT/'tools/test-i386-task-document-update.py'
OWNER_BASE = ROOT/'tools/test-i386-render-owner-retire.py'
COMMANDS = list(runpy.run_path(str(BASE))['COMMANDS'][:20])
COMMANDS += [
    ('CTask *pw_worker;CDoc *pw_saved;I64 pw_caught,pw_frames;Bool pw_request,pw_stop;', []),
    ("U0 PWCancel(){throw('WinAbort',TRUE);}", []),
    ('U0 PWFrame(){if(pw_request){pw_request=FALSE;if(NativeGraphicsPresent(&RTDraw))pw_frames++;}else Yield;}', []),
    ("U0 PWWorker(U8 *data){while(!pw_stop){Fs->task_end_cb=&PWCancel;try{PWFrame;}catch{if(Fs->except_ch=='WinAbort'){pw_caught++;Fs->catch_except=TRUE;}else rt_error=Fs->except_ch;}}Fs->task_end_cb=NULL;}", []),
    ('U0 PWDoc(){rt_doc=DocNew("Worker.DD");rt_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;RTEntry(&RTTag);Fs->display_doc=rt_doc;}', []),
    ('U0 PWSetup(){RTReset(8);rt_owner=Fs;pw_saved=Fs->display_doc;pw_caught=pw_frames=0;pw_stop=FALSE;PWDoc;pw_request=TRUE;pw_worker=Spawn(&PWWorker,NULL,"Refresh worker",-1,Fs,16384);while(!rt_stage)Yield;}', []),
    ('I64 PWCancelRun(){I64 m=0;PWSetup;if(rt_live)m|=1;DocDel(rt_doc);rt_doc=NULL;if(TaskValidate(pw_worker)&&pw_caught==1&&!pw_frames&&!rt_error)m|=2;return m;}', []),
    ('I64 PWReplace(I64 m){rt_mode=7;rt_stage=0;PWDoc;pw_request=TRUE;while(!pw_frames)Yield;if(TaskValidate(pw_worker)&&pw_caught==1&&rt_live&&!rt_doc->owning_task&&!StrCmp(rt_doc->head.next(CDocEntry *)->tag,"alive"))m|=4;return m;}', []),
    ('I64 PWFinish(I64 m){pw_stop=TRUE;while(TaskValidate(pw_worker))Yield;RTTurn;FlushMsgs;Fs->display_doc=pw_saved;DocDel(rt_doc);if(Fs->data_heap->used_u8s==rt_before)m|=8;return RTRetry(m);}', []),
    ('PWFinish(PWReplace(PWCancelRun));', ['63']),
    ('6*7;', ['42']),
]
if any(len(source)>255 for source, _ in COMMANDS):
    raise ValueError('Worker recovery fixture exceeds the interactive line limit')


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
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve(), BASE, OWNER_BASE]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Persistent managed renderer recovers cancellation using original task-end callback semantics, retires old document and renders replacement on the same task; not scheduled refresh',
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
