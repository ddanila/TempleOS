#!/usr/bin/env python3
"""Check repeated large real-source DolDoc loads and exact byte round trips."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands(cycles=3):
    result=[('I64 lr_size=0;U8 *lr_raw=FileRead("C:/Kernel/I386/RedSeaCreate.HC",&lr_size);lr_size;', ['11210'])]
    for cycle in range(cycles):
        doc=f'lr_doc{cycle}';saved=f'lr_saved{cycle}';size=f'lr_size{cycle}'
        result.extend([
            (f'CDoc *{doc}=DocRead("C:/Kernel/I386/RedSeaCreate.HC",DOCF_NO_CURSOR);{doc}!=0;', ['1']),
            (f'I64 {size}=0;U8 *{saved}=DocSave({doc},&{size});{size}==lr_size && !StrCmp({saved},lr_raw);', ['1']),
            (f'DocDel({doc});Free({saved});6*7;', ['42'])])
    result.append(('Free(lr_raw);6*7;', ['42']))
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--cycles',type=int,default=3)
    parser.add_argument('--writable-copy',action='store_true',help='Run on a fresh disk copy without QEMU snapshot temporary files')
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
    disk=args.disk
    if args.writable_copy:
        disk=args.out/'working.img'
        shutil.copyfile(args.disk,disk)
    report['disk_policy']='writable copy' if args.writable_copy else 'QEMU snapshot'
    try:
        report['behavior']=runpy.run_path(str(helper))['run_input'](
            disk,args.out/'behavior',cpu='486,-fpu',qmp_stdio=True,
            snapshot=not args.writable_copy,
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
