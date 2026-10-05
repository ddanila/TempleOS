#!/usr/bin/env python3
"""Check repeated large real-source DolDoc loads and exact byte round trips."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles=3):
    result=[('I64 lr_size=0,lr_saved_size=0;U8 *lr_raw=FileRead("C:/Kernel/I386/RedSeaCreate.HC",&lr_size);lr_size;', ['11210']),
            ('CDoc *lr_doc;U8 *lr_saved;', [])]
    for cycle in range(cycles):
        result.extend([
            ('lr_doc=DocRead("C:/Kernel/I386/RedSeaCreate.HC",DOCF_NO_CURSOR);lr_doc!=0;', ['1']),
            ('lr_saved=DocSave(lr_doc,&lr_saved_size);lr_saved_size==lr_size && !StrCmp(lr_saved,lr_raw);', ['1']),
            ('DocDel(lr_doc);Free(lr_saved);6*7;', ['42'])])
    result.append(('Free(lr_raw);6*7;', ['42']))
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--cycles',type=int,default=3)
    args=parser.parse_args()
    if not 1<=args.cycles<=20:parser.error('cycles must be 1..20')
    if args.out.exists():parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
    helper=ROOT/'tools/i386-kernel-input.py'
    inputs={str(path.resolve()):sha(path) for path in (args.disk,helper,Path(__file__))}
    report=dict(result='running',input_sha256=inputs,
                cycles=args.cycles,
                scope='Read 11210-byte real source, load/save exact bytes and free, repeatedly; not all DolDoc or memory behavior')
    try:
        report['behavior']=runpy.run_path(str(helper))['run_input'](
            args.disk,args.out/'behavior',cpu='486,-fpu',qmp_stdio=True,
            startup_check={'status':'ok','answers':[],'commands':commands(args.cycles)})
        report['result']='pass'
    except Exception as error:
        report.update(result='fail',error=str(error))
        raise
    finally:
        if any(sha(Path(p))!=digest for p,digest in inputs.items()):
            report.update(result='fail',error='Large-document fixture inputs changed')
        (args.out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
