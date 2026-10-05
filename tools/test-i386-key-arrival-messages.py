#!/usr/bin/env python3
"""Check keyboard arrival timestamps through private and public message consumption."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [
        ('HashFind("I386PostKeyTimed",Fs->hash_table,HTT_EXPORT_SYS_SYM)!=0&&HashFind("I386ScanKeyTimed",Fs->hash_table,HTT_EXPORT_SYS_SYM)!=0;', ['1']),
        ('U0 (*ap)(CTask *t,I64 c,I64 a,I64 b,I64 f,I64 j)=HashFind("I386PostKeyTimed",Fs->hash_table,HTT_EXPORT_SYS_SYM)->val;', []),
        ('I64 (*ks)(I64 *a,I64 *b,I64 m,CTask *t,I64 *j)=HashFind("I386ScanKeyTimed",Fs->hash_table,HTT_EXPORT_SYS_SYM)->val;', []),
        ('I64 ka,kb,kj;', []),
        ('ap(Fs,2,65,123,0,100);Sleep(1500);I64 kc=ks(&ka,&kb,4,Fs,&kj);kc==2&&ka==65&&kb==123&&kj==100;', ['1']),
        ('PostMsg(Fs,2,66,321);I64 kd=ks(&ka,&kb,4,Fs,&kj);kd==2&&ka==66&&kb==321&&kj==-1;', ['1']),
        ('ap(Fs,2,67,234,0,200);I64 ke=ScanMsg(&ka,&kb,4);ke==2&&ka==67&&kb==234;', ['1']),
        ('I64 KH(){I64 f=GetRFlags,b;SetRFlags(f&~512);FlushMsgs;b=adam_task->data_heap->used_u8s;ap(Fs,2,65,0,0,100);ks(&ka,&kb,4,Fs,&kj);SetRFlags(f);return adam_task->data_heap->used_u8s==b;}', []),
        ('KH;', ['1']), ('KH;', ['1']), ('(GetRFlags&512)!=0;', ['1']), ('6*7;', ['42'])]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if args.out.exists():parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
    helper=ROOT/'tools/i386-kernel-input.py'
    inputs={str(path.resolve()):sha(path) for path in (args.disk,helper,Path(__file__))}
    report=dict(result='running',input_sha256=inputs,
                scope='Timed message survives 1500ms delay; public PostMsg fallback, public ScanMsg arguments, exact root heap cleanup twice and IF restore; not all keyboard/filter/macro behavior')
    try:
        report['behavior']=runpy.run_path(str(helper))['run_input'](
            args.disk,args.out/'behavior',cpu='486,-fpu',qmp_stdio=True,
            startup_check={'status':'ok','answers':[],'commands':commands()})
        report['result']='pass'
    except Exception as error:
        report.update(result='fail',error=str(error))
        raise
    finally:
        if any(sha(Path(p))!=digest for p,digest in inputs.items()):
            report.update(result='fail',error='Arrival-message fixture inputs changed')
        (args.out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
