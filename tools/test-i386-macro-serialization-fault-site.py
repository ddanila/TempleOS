#!/usr/bin/env python3
"""Inject a serializer temporary-allocation failure and require exact heap recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(fail_after=2, allocator="CAlloc"):
    rows = [
        ('#include "/Kernel/SymbolTypes.HH"', []),
        ('CJob *mf_heap_head;U8 *mfa_entry,*mfa_hook,mfa_saved[5];I64 mfa_calls,mfa_base;Bool mfa_caught;', []),
        ('U0 MFARestore(){I64 i;for(i=0;i<5;i++)mfa_entry[i]=mfa_saved[i];}', []),
        ('U0 MFAApply(){I32 d=(mfa_hook+0)(U64)-(mfa_entry+0)(U64)-5;mfa_entry[0]=0xE9;(mfa_entry+1)(I32 *)[0]=d;}', []),
        ("U8 *MFAHook(I64 size,CTask *task=0){U8 *p;if(++mfa_calls==2)throw('OutMem');MFARestore;p=CAlloc(size,task);MFAApply;return p;}", []),
        ('U0 MFABuild(){I64 i;CJob *j;mf_heap_head=CAlloc(sizeof(CJob));QueInit(mf_heap_head);for(i=0;i<2;i++){j=CAlloc(sizeof(CJob));j->job_code=1;j->msg_code=2;j->aux1=65+i;QueIns(j,mf_heap_head->last);}}', []),
        ('U0 MFAStart(){I64 i;mfa_hook=&MFAHook;mfa_entry=&CAlloc;for(i=0;i<5;i++)mfa_saved[i]=mfa_entry[i];mfa_calls=0;mfa_base=Fs->data_heap->used_u8s;MFAApply;}', []),
        ("U0 MFATry(){U8 *s;mfa_caught=FALSE;try{s=SysMacro2Str(mf_heap_head);Free(s);}catch{mfa_caught=Fs->except_ch=='OutMem';Fs->catch_except=TRUE;}}", []),
        ('Bool MFABytes(){I64 i;for(i=0;i<5;i++)if(mfa_entry[i]!=mfa_saved[i])return FALSE;return TRUE;}', []),
        ('Bool MFARun(){I64 f=GetRFlags;Bool ok;SetRFlags(f&~512);MFAStart;MFATry;MFARestore;ok=MFABytes&&mfa_caught&&mfa_calls==2&&Fs->data_heap->used_u8s==mfa_base;SetRFlags(f);return ok;}', []),
        ('U0 MFAFree(){CJob *j;while(mf_heap_head->next!=mf_heap_head){j=mf_heap_head->next;QueRem(j);Free(j);}Free(mf_heap_head);}', []),
        ('MFABuild;MFARun;', ['1']),
        ('MFAFree;6*7;', ['42']),
    ]
    return [(s.replace('++mfa_calls==2', '++mfa_calls=='+str(fail_after))
             .replace('mfa_calls==2', 'mfa_calls=='+str(fail_after))
             .replace('p=CAlloc(size,task)', 'p='+allocator+'(size,task)')
             .replace('mfa_entry=&CAlloc', 'mfa_entry=&'+allocator), answers)
            for s, answers in rows]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--allocator', choices=('CAlloc','MAlloc'), default='CAlloc')
    parser.add_argument('--fail-after', type=int, default=2)
    args = parser.parse_args()
    if args.fail_after < 1: parser.error('fail-after must be positive')
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, Path(__file__))}
    report = dict(result='running', allocator=args.allocator, fail_after=args.fail_after, input_sha256=pins, disk_policy='writable copy',
                  scope='Selected allocator call throws OutMem; exception/count, exact restored entry bytes and task heap recovery; each invocation qualifies only its selected fault site, not playback')
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    try:
        disk = args.out / 'working.img'
        shutil.copyfile(args.disk, disk)
        report['behavior'] = runpy.run_path(str(helper))['run_input'](
            disk, args.out / 'behavior', cpu='486,-fpu', qmp_stdio=True, snapshot=False,
            startup_check={'status': 'ok', 'answers': [], 'commands': commands(args.fail_after,args.allocator)})
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
