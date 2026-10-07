#!/usr/bin/env python3
"""Cancel a queued actual macro playback filter and require exact caller recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('U0 MCAdd(I64 ch){CJob *j=CAlloc(sizeof(CJob));j->job_code=1;j->msg_code=2;j->aux1=ch;QueIns(j,sys_macro_head.last);}', []), ("U0 MCBuild(){if(sys_macro_head.next!=&sys_macro_head)throw('MacroTst');MCAdd(65);MCAdd(66);sys_focus_task=Fs;}", []), ('MCBuild;', []), ('I64 mc_base;CTask *mc_filter;Bool mc_queued,mc_retired;', []), ('Bool MCState(){return Fs->last_input_filter_task==Fs&&Fs->next_input_filter_task==Fs&&!Bt(&Fs->task_flags,TASKf_FILTER_INPUT);}', []), ('Bool MCRing(){return sys_macro_head.next->aux1==65&&sys_macro_head.last->aux1==66&&sys_macro_head.next->next==sys_macro_head.last&&sys_macro_head.last->next==&sys_macro_head&&!Bt(&sys_semas[SEMA_RECORD_MACRO],0);}', []), ('U0 MCQueue(){mc_base=Fs->data_heap->used_u8s;LBts(&sys_semas[SEMA_RECORD_MACRO],0);PlaySysMacro(1);mc_filter=Fs->last_input_filter_task;mc_queued=mc_filter!=Fs&&TaskValidate(mc_filter);}', []), ('Bool MCCancel(){Kill(mc_filter);mc_retired=!TaskValidate(mc_filter);return mc_queued&&mc_retired&&MCState()&&MCRing()&&Fs->data_heap->used_u8s==mc_base;}', []), ('Bool MCRun(){I64 f=GetRFlags;Bool ok;SetRFlags(f&~512);MCQueue;ok=MCCancel;SetRFlags(f);return ok;}', []), ('MCRun;', ['1']), ('U0 MCFree(){CJob *j;while(sys_macro_head.next!=&sys_macro_head){j=sys_macro_head.next;QueRem(j);Free(j);}}', []), ('MCFree;', []), ('6*7;', ['42'])]

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
                  scope='Actual PlaySysMacro queued while interrupts disabled, then Kill before filter entry; exact caller heap, filter links and flags, ring preservation, recording disabled and continued console; not active execution cancellation or complete root heap qualification')
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
            report.update(result='fail', error='Macro-serialization fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Macro serialization failed'))


if __name__ == '__main__':
    main()
