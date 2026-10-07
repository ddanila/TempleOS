#!/usr/bin/env python3
"""Inject an In allocation failure and check exception, filters and both heaps."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(fail_after=2, allocator="MAlloc", operation="In"):
    rows = [
        ('U8 *ia_entry,*ia_hook,ia_saved[5];I64 ia_calls,ia_base,ia_root,ia_sizes[16];Bool ia_caught;', []),
        ('U0 IARestore(){I64 i;for(i=0;i<5;i++)ia_entry[i]=ia_saved[i];}', []),
        ('U0 IAApply(){I32 d=(ia_hook+0)(U64)-(ia_entry+0)(U64)-5;ia_entry[0]=0xE9;(ia_entry+1)(I32 *)[0]=d;}', []),
        ("U8 *IAHook(I64 size,CTask *task=0){U8 *p;ia_calls++;if(ia_calls<=16)ia_sizes[ia_calls-1]=size;if(ia_calls==2){IARestore;throw('OutMem');}IARestore;p=MAlloc(size,task);IAApply;return p;}", []),
        ('U0 IAArm(){I64 i;ia_hook=&IAHook;ia_entry=&MAlloc;for(i=0;i<5;i++)ia_saved[i]=ia_entry[i];ia_calls=0;IAApply;}', []),
        ("U0 IATry(){ia_caught=FALSE;try{In(\"%s\",\"Fault\");}catch{ia_caught=Fs->except_ch=='OutMem';Fs->catch_except=TRUE;}}", []),
        ('Bool IABytes(){I64 i;for(i=0;i<5;i++)if(ia_entry[i]!=ia_saved[i])return FALSE;return TRUE;}', []),
        ('I64 IAState(){I64 m=0;if(IABytes)m|=1;if(ia_caught)m|=2;if(ia_calls==2)m|=4;if(Fs->last_input_filter_task==Fs&&Fs->next_input_filter_task==Fs)m|=8;if(Fs->data_heap->used_u8s==ia_base)m|=16;if(adam_task->data_heap->used_u8s==ia_root)m|=32;return m;}', []),
        ('I64 IARun(){I64 f=GetRFlags,m;SetRFlags(f&~512);ia_base=Fs->data_heap->used_u8s;ia_root=adam_task->data_heap->used_u8s;IAArm;IATry;IARestore;m=IAState;SetRFlags(f);return m;}', []),
        ('IARun;', ['63']), ('6*7;', ['42']),
    ]
    result = [(source.replace('ia_calls==2', 'ia_calls=='+str(fail_after))
               .replace('p=MAlloc(size,task)', 'p='+allocator+'(size,task)')
               .replace('ia_entry=&MAlloc', 'ia_entry=&'+allocator), answers)
              for source, answers in rows]
    if operation == 'MStrPrint':
        result = [(source.replace('In(\"%s\",\"Fault\");', 'U8 *p=MStrPrint(\"%s\",\"Fault\");Free(p);'), answers) for source, answers in result]
    if operation == 'TaskExe':
        result = [(source.replace('In(\"%s\",\"Fault\");', 'CJob *p=TaskExe(Fs,Fs,\"6*7;\",0);if(p){QueRem(p);JobDel(p);}')
                   .replace('Fs->last_input_filter_task==Fs&&Fs->next_input_filter_task==Fs', 'IAQueues'), answers) for source, answers in result]
        result.insert(7, ('Bool IAQueues(){return Fs->srv_ctrl.next_waiting==&Fs->srv_ctrl.next_waiting&&Fs->srv_ctrl.next_done==&Fs->srv_ctrl.next_done&&!Bt(&Fs->srv_ctrl.flags,JOBCf_LOCKED);}', []))
    if any(len(source)>255 for source, answers in result):
        raise ValueError('Fault fixture exceeds console capacity')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--operation', choices=('In','MStrPrint','TaskExe'), default='In')
    parser.add_argument('--allocator', choices=('CAlloc','MAlloc'), default='MAlloc')
    parser.add_argument('--fail-after', type=int, default=2)
    args = parser.parse_args()
    if args.fail_after < 1: parser.error('fail-after must be positive')
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, Path(__file__))}
    report = dict(result='running', allocator=args.allocator, fail_after=args.fail_after, operation=args.operation, input_sha256=pins, disk_policy='writable copy',
                  scope='Selected operation allocator call throws OutMem; exact exception/count, restored entry bytes, restored input rings and exact caller/root heap; no other fault sites or active cancellation coverage')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands(args.fail_after,args.allocator,args.operation)})
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        changed = [path for path, digest in pins.items() if sha(Path(path)) != digest]
        if changed:
            report.update(result='fail', error='Input formatting fault fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Input formatting fault recovery failed'))


if __name__ == '__main__':
    main()
