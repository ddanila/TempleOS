#!/usr/bin/env python3
"""Require original macro serialization and playback services in the installed guest."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('U0 MPAdd(I64 ch){CJob *j=CAlloc(sizeof(CJob));j->job_code=1;j->msg_code=2;j->aux1=ch;QueIns(j,sys_macro_head.last);}', []), ("U0 MPBuild(){if(sys_macro_head.next!=&sys_macro_head)throw('MacroTst');MPAdd(65);MPAdd(66);}", []), ('MPBuild;', []), ('Bool MPState(){return sys_macro_head.next->aux1==65&&sys_macro_head.last->aux1==66&&sys_macro_head.next->next==sys_macro_head.last&&sys_macro_head.last->next==&sys_macro_head&&!Bt(&sys_semas[SEMA_RECORD_MACRO],0);}', []), ('CTask *mr_focus,*mr_task;I64 mr_base;', []), ('U0 MRIdle(U8 *data){while(TRUE)Sleep(1);}', []), ('U0 MRSpawn(){mr_task=Spawn(&MRIdle,0,"Retired macro target",-1,Fs);}', []), ('MRSpawn;', []), ('Kill(mr_task);', ['1']), ('TaskValidate(mr_task);', ['0']), ('U0 MRStart(CTask *task){mr_focus=sys_focus_task;sys_focus_task=task;mr_base=Fs->data_heap->used_u8s;LBts(&sys_semas[SEMA_RECORD_MACRO],0);}', []), ('Bool MREnd(){Bool kept=Bt(&sys_semas[SEMA_RECORD_MACRO],0);LBtr(&sys_semas[SEMA_RECORD_MACRO],0);sys_focus_task=mr_focus;return kept&&MPState()&&Fs->data_heap->used_u8s==mr_base&&Fs->last_input_filter_task==Fs;}', []), ('Bool MRRun(CTask *task){MRStart(task);PlaySysMacro(3);return MREnd();}', []), ('MRRun(NULL);', ['1']), ('MRRun(mr_task);', ['1']), ('U0 MPFree(){CJob *j;while(sys_macro_head.next!=&sys_macro_head){j=sys_macro_head.next;QueRem(j);Free(j);}}', []), ('MPFree;', []), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, Path(__file__))}
    report = dict(result='running', input_sha256=pins, disk_policy='writable copy',
                  scope='Null and retired focused recipient: PlaySysMacro leaves recording bit set as original validation-before-disable semantics, preserves ring and exact caller heap, no filter added; test restores focus/recording and verifies continued console use; not mid-playback retirement or cancellation')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands()})
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [path for path, digest in pins.items() if sha(Path(path)) != digest]
        if changed:
            report.update(result='fail', error='Macro-playback fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Macro-playback prerequisites failed'))


if __name__ == '__main__':
    main()
