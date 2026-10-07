#!/usr/bin/env python3
"""Complete forward-declared base and derived classes interactively."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def commands():
    return [('extern class ForwardBase;', []),
            ('class ForwardBase {I64 value;};', []),
            ('extern class ForwardChild;', []),
            ('class ForwardChild:ForwardBase {I64 extra;};', []),
            ('sizeof(ForwardChild)==16;', ['1']),
            ('ForwardChild child;child.value=6;child.extra=7;child.value*child.extra;', ['6','7','42'])]


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
                scope='Published forward class completion with inheritance, exact layout and inherited member access; not all compiler behavior')
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
            report.update(result='fail',error='Forward-inheritance fixture inputs changed')
        (args.out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
