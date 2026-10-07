#!/usr/bin/env python3
"""Inject a MenuNew allocation failure and check exception, lock and heap recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(fail_after=4, allocator="CAlloc"):
    rows = [
        ('U8 *df_entry,*df_hook,df_saved[5];I64 df_calls,df_base,df_delta;Bool df_caught;CMenu *df_menu;CCmpCtrl *df_boundary;', []),
        ('U0 DFRestore(){I64 i;for(i=0;i<5;i++)df_entry[i]=df_saved[i];}', []),
        ('U0 DFApply(){I32 d=(df_hook+0)(U64)-(df_entry+0)(U64)-5;df_entry[0]=0xE9;(df_entry+1)(I32 *)[0]=d;}', []),
        ("U8 *DFHook(I64 size,CTask *task=0){U8 *p;df_calls++;if(df_calls==4){DFRestore;throw('OutMem');}DFRestore;p=CAlloc(size,task);DFApply;return p;}", []),
        ('U0 DFArm(){I64 i;df_hook=&DFHook;df_entry=&CAlloc;for(i=0;i<5;i++)df_saved[i]=df_entry[i];df_calls=0;DFApply;}', []),
        ("U0 DFTry(){df_caught=FALSE;try{df_menu=MenuNew(\"File{Open(2,65,0);Close(3,66,1);}Help{About(4,67,2);}\");}catch{df_caught=Fs->except_ch=='OutMem';Fs->catch_except=TRUE;}}", []),
        ('Bool DFBytes(){I64 i;for(i=0;i<5;i++)if(df_entry[i]!=df_saved[i])return FALSE;return TRUE;}', []),
        ('I64 DFState(){I64 m=0;if(DFBytes)m|=1;if(df_caught)m|=2;if(df_calls==4)m|=4;if(Fs->last_cc==df_boundary)m|=8;if(!df_menu)m|=32;return m;}', []),
        ('I64 DFFinish(I64 m){if(df_menu)MenuDel(df_menu);df_delta=Fs->data_heap->used_u8s-df_base;if(!df_delta)m|=16;return m;}', []),
        ('I64 DFRun(){I64 f=GetRFlags,m;SetRFlags(f&~512);df_base=Fs->data_heap->used_u8s;df_boundary=Fs->last_cc;df_menu=NULL;DFArm;DFTry;DFRestore;m=DFFinish(DFState);SetRFlags(f);return m;}', []),
        ('DFRun;', ['63']),
        ('6*7;', ['42']),
    ]
    result = [(source.replace('df_calls==4','df_calls=='+str(fail_after)).replace('p=CAlloc(size,task)','p='+allocator+'(size,task)').replace('df_entry=&CAlloc','df_entry=&'+allocator),answers) for source,answers in rows]
    if any(len(source)>255 for source,answers in result): raise ValueError('Fault command exceeds console capacity')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--allocator', choices=('CAlloc','MAlloc'), default='CAlloc')
    parser.add_argument('--fail-after', type=int, default=4)
    args = parser.parse_args()
    if args.fail_after < 1: parser.error('fail-after must be positive')
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = ROOT / 'tools/i386-kernel-input.py'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    pins = {str(p.resolve()): sha(p) for p in (args.disk, helper, Path(__file__))}
    report = dict(result='running', allocator=args.allocator, fail_after=args.fail_after, input_sha256=pins, disk_policy='writable copy',
                  scope='Selected MenuNew allocator failure: propagated OutMem, restored allocator bytes/count, no returned menu, recovered compiler boundary and exact caller heap; not root heap, other sites or menu-file/action coverage')
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
            report.update(result='fail', error='Menu fault fixture inputs changed', changed_inputs=changed)
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise RuntimeError(report.get('error', 'Menu fault recovery failed'))


if __name__ == '__main__':
    main()
