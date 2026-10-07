#!/usr/bin/env python3
"""Compile the canonical symbol header and use its export class interactively."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('CHash *ancestor_fun=HashFind("CHashFun",Fs->hash_table->next,HTT_CLASS);ancestor_fun!=0;', ['1']),
            ('#include "/Kernel/SymbolTypes.HH"', []),
            ('sizeof(CHashExport)>sizeof(CHash);', ['1']),
            ('HashFind("CHashFun",Fs->hash_table,HTT_CLASS)!=ancestor_fun;', ['1']),
            ('HashFind("CHashFun",Fs->hash_table->next,HTT_CLASS)==ancestor_fun;', ['1']),
            ('ancestor_fun(CHashClass *)->size==0&&sizeof(CHashFun)>0;', ['1']),
            ('6*7;', ['42'])]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--writable-copy',action='store_true',help='Run on a fresh disk copy without QEMU snapshot temporary files')
    args=parser.parse_args()
    if args.out.exists():parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
    helper=ROOT/'tools/i386-kernel-input.py'
    inputs={str(path.resolve()):sha(path) for path in (args.disk,helper,Path(__file__))}
    report=dict(result='running',input_sha256=inputs,
                scope='Canonical SymbolTypes compilation, local shadow with stable untouched ancestor forward, export layout and console recovery; not all compiler behavior')
    disk=args.disk
    if args.writable_copy:
        disk=args.out/'working.img'
        shutil.copyfile(args.disk,disk)
    report['disk_policy']='writable copy' if args.writable_copy else 'QEMU snapshot'
    try:
        report['behavior']=runpy.run_path(str(helper))['run_input'](
            disk,args.out/'behavior',cpu='486,-fpu',qmp_stdio=True,
            snapshot=not args.writable_copy,
            startup_check={'status':'ok','answers':[],'commands':commands()})
        report['result']='pass'
    except Exception as error:
        report.update(result='fail',error=str(error))
        raise
    finally:
        if any(sha(Path(p))!=digest for p,digest in inputs.items()):
            report.update(result='fail',error='Symbol-header fixture inputs changed')
        (args.out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
