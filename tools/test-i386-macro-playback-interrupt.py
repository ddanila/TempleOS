#!/usr/bin/env python3
"""Interrupt actual repeated playback while waiting for its first queued filter."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('U0 MIAdd(I64 ch){CJob *j=CAlloc(sizeof(CJob));j->job_code=1;j->msg_code=2;j->aux1=ch;QueIns(j,sys_macro_head.last);}', []), ("U0 MIBuild(){if(sys_macro_head.next!=&sys_macro_head)throw('MacroTst');MIAdd(65);MIAdd(66);sys_focus_task=Fs;}", []), ('MIBuild;', []), ('U8 *mi_entry,mi_saved[5];I64 mi_calls,mi_base,mi_root,mi_delta,mi_root_delta;Bool mi_caught,mi_flags;', []), ('U0 MIRestore(){I64 i;for(i=0;i<5;i++)mi_entry[i]=mi_saved[i];}', []), ("U0 MIHook(){mi_calls++;throw('Break');}", []), ('U0 MIPatch(){I64 i;I32 d;mi_entry=&Yield;for(i=0;i<5;i++)mi_saved[i]=mi_entry[i];d=(&MIHook+0)(U64)-(mi_entry+0)(U64)-5;mi_entry[0]=0xE9;(mi_entry+1)(I32 *)[0]=d;}', []), ('Bool MIBytes(){I64 i;for(i=0;i<5;i++)if(mi_entry[i]!=mi_saved[i])return FALSE;return TRUE;}', []), ('U0 MIStart(){Sleep(100);FlushMsgs(Fs);mi_base=Fs->data_heap->used_u8s;mi_root=Fs->parent_task->data_heap->used_u8s;mi_calls=0;mi_caught=FALSE;LBts(&sys_semas[SEMA_RECORD_MACRO],0);MIPatch;}', []), ("U0 MITry(){try{PlaySysMacro(2);}catch{mi_caught=Fs->except_ch=='Break';Fs->catch_except=TRUE;}MIRestore;}", []), ('Bool MIState(){return Fs->last_input_filter_task==Fs&&Fs->next_input_filter_task==Fs&&!Bt(&Fs->task_flags,TASKf_FILTER_INPUT);}', []), ('Bool MIRing(){return sys_macro_head.next->aux1==65&&sys_macro_head.last->aux1==66&&sys_macro_head.next->next==sys_macro_head.last&&sys_macro_head.last->next==&sys_macro_head&&!Bt(&sys_semas[SEMA_RECORD_MACRO],0);}', []), ('I64 MIScan(){I64 a,b;if(ScanMsg(&a,&b,1<<2,Fs)!=2||a!=65||b)return 0;if(ScanMsg(&a,&b,1<<2,Fs)!=2||a!=66||b)return 0;return ScanMsg(&a,&b,1<<2,Fs)==0;}', []), ('Bool mi_receipt;', []), ('U0 MIRun(){I64 f;MIStart;f=GetRFlags;MITry;mi_flags=(GetRFlags&512)==(f&512);TaskWait(Fs,FALSE);mi_receipt=MIScan;FlushMsgs(Fs);mi_delta=Fs->data_heap->used_u8s-mi_base;mi_root_delta=Fs->parent_task->data_heap->used_u8s-mi_root;}', []), ('MIRun;', []), ('mi_caught&&mi_calls==1&&mi_flags;', ['1']), ('mi_receipt&&MIState()&&MIRing()&&MIBytes();', ['1']), ('mi_delta;', ['0']), ('mi_root_delta;', ['0']), ('U0 MIFree(){CJob *j;while(sys_macro_head.next!=&sys_macro_head){j=sys_macro_head.next;QueRem(j);Free(j);}}', []), ('MIFree;', []), ('6*7;', ['42'])]

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
                  scope='Actual PlaySysMacro(2) interrupted by Break at public Yield in second repeat wait; restored entry/IRQ state, first queued repeat drains exactly AB, no second repeat, exact caller/root heap with keyboard queues drained, preserved ring/filter state; selected interruption site')
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
