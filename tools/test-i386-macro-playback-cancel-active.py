#!/usr/bin/env python3
"""Cancel an executing actual macro filter paused at the public message service."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('U0 MCAdd(I64 ch){CJob *j=CAlloc(sizeof(CJob));j->job_code=1;j->msg_code=2;j->aux1=ch;QueIns(j,sys_macro_head.last);}', []), ("U0 MCBuild(){if(sys_macro_head.next!=&sys_macro_head)throw('MacroTst');MCAdd(65);MCAdd(66);sys_focus_task=Fs;}", []), ('MCBuild;', []), ('U8 *mc_entry,mc_saved[5];CTask *mc_filter;Bool mc_entered;I64 mc_base,mc_root,mc_delta,mc_root_delta;', []), ('U0 MCRestore(){I64 i;for(i=0;i<5;i++)mc_entry[i]=mc_saved[i];}', []), ('U0 MCHook(I64 code,I64 a,I64 b,I64 flags=0){mc_filter=Fs;mc_entered=TRUE;Sleep(10000);}', []), ('U0 MCPatch(){I64 i;I32 d;mc_entry=&Msg;for(i=0;i<5;i++)mc_saved[i]=mc_entry[i];d=(&MCHook+0)(U64)-(mc_entry+0)(U64)-5;mc_entry[0]=0xE9;(mc_entry+1)(I32 *)[0]=d;}', []), ('Bool MCState(){return Fs->last_input_filter_task==Fs&&Fs->next_input_filter_task==Fs&&!Bt(&Fs->task_flags,TASKf_FILTER_INPUT);}', []), ('Bool MCRing(){return sys_macro_head.next->aux1==65&&sys_macro_head.last->aux1==66&&sys_macro_head.next->next==sys_macro_head.last&&sys_macro_head.last->next==&sys_macro_head&&!Bt(&sys_semas[SEMA_RECORD_MACRO],0);}', []), ('U0 MCStart(){Sleep(100);FlushMsgs(Fs);mc_base=Fs->data_heap->used_u8s;mc_root=Fs->parent_task->data_heap->used_u8s;mc_entered=FALSE;MCPatch;LBts(&sys_semas[SEMA_RECORD_MACRO],0);PlaySysMacro(1);while(!mc_entered)Yield;}', []), ('U0 MCCancel(){Kill(mc_filter);MCRestore;}', []), ('Bool MCBytes(){I64 i;for(i=0;i<5;i++)if(mc_entry[i]!=mc_saved[i])return FALSE;return TRUE;}', []), ('U0 MCRun(){MCStart;MCCancel;FlushMsgs(Fs);mc_delta=Fs->data_heap->used_u8s-mc_base;mc_root_delta=Fs->parent_task->data_heap->used_u8s-mc_root;}', []), ('MCRun;', []), ('mc_entered&&!TaskValidate(mc_filter);', ['1']), ('MCState()&&MCRing()&&MCBytes();', ['1']), ('mc_delta==0;', ['1']), ('mc_root_delta;', ['0']), ('Bool MCRepeat(){I64 i;for(i=0;i<10;i++){MCRun;if(!mc_entered||TaskValidate(mc_filter)||!MCState()||!MCRing()||!MCBytes()||mc_delta||mc_root_delta)return FALSE;}return TRUE;}', []), ('MCRepeat;', ['1']), ('U0 MCFree(){CJob *j;while(sys_macro_head.next!=&sys_macro_head){j=sys_macro_head.next;QueRem(j);Free(j);}}', []), ('MCFree;', []), ('6*7;', ['42'])]

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
                  scope='Actual PlaySysMacro enters message hook and sleeps; Kill active filter; exact caller and parent root heap, restored message entry, filter links and flags, ring preservation and recording disabled; selected active cancellation checkpoint, initial plus ten repeated cycles, caller keyboard messages drained before/after heap measurement')
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
