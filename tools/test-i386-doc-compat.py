#!/usr/bin/env python3
"""Prove that original TempleOS reads a document serialized by native i386."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
INPUT=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
FILES=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents']


def run(*args):
    subprocess.run(args,cwd=ROOT,check=True)


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=Path,nargs='?',default=ROOT/'build/i386-kernel/kernel.img')
    parser.add_argument('--out',type=Path,default=ROOT/'build/i386-doc-compat')
    parser.add_argument('--qmp-stdio',action='store_true',
                        help='Control both QEMU guests over stdio')
    args=parser.parse_args()
    source=args.source.resolve()
    source_hash=sha256(source)
    out=args.out
    out.mkdir(parents=True,exist_ok=True)
    (out/'result.json').unlink(missing_ok=True)
    disk=out/'native.img'
    shutil.copyfile(source,disk)
    native_run=INPUT(disk,out/'native',qmp_stdio=args.qmp_stdio,startup_check={
        'status':'ok','answers':[],
        'commands':[
            ('#include "/Kernel/I386/DocBinaryPersistenceCheck.HC"',[]),
            ('DocBinaryPersistenceCheck;',['8'])]},snapshot=False)
    files=FILES(disk,{'/BinaryRecord.DD'})
    native=files.get('/BinaryRecord.DD')
    if native is None or len(native)!=37:
        raise ValueError('Native compatibility document was not persisted')
    overlay=out/'overlay'
    overlay.mkdir(exist_ok=True)
    (overlay/'NativeCompat.DD').write_bytes(native)
    iso=out/'original-reader.iso'
    exports=out/'original'
    run(sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay',
        '--overlay','tests/guest/i386-doc-compat','--overlay',str(overlay),
        '--output',str(iso))
    guest_command=[sys.executable,'tools/guest-run.py',str(iso),
                   '--out',str(exports),'--timeout','90']
    if args.qmp_stdio: guest_command.append('--qmp-stdio')
    run(*guest_command)
    round_trip=(exports/'NativeRoundTrip.DD').read_bytes()
    if round_trip!=native:
        raise ValueError('Original DocRead/DocSave changed the native document bytes')
    if sha256(source)!=source_hash:
        raise ValueError('Compatibility test changed the source image')
    result={'result':'pass','native_run':native_run,'bytes':len(native),
            'sha256':hashlib.sha256(native).hexdigest(),
            'original_round_trip':'byte exact',
            'source_disk_sha256':source_hash,'source_unchanged':True}
    (out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
    print('PASS: original TempleOS read and reproduced the native i386 document')


if __name__=='__main__': main()
