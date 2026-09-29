#!/usr/bin/env python3
"""Power-cut and retry a guest-built i386 boot-image installation in QEMU."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import signal
import threading
import time

ROOT=Path(__file__).resolve().parents[1]


def load_tool(name,path):
    spec=importlib.util.spec_from_file_location(name,ROOT/path)
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def qemu_for_debug_log(log):
    expected=('file:'+str(log.resolve())).encode()
    for entry in Path('/proc').iterdir():
        if not entry.name.isdigit(): continue
        try: argv=(entry/'cmdline').read_bytes().split(b'\0')
        except OSError: continue
        if argv and Path(argv[0].decode(errors='replace')).name=='qemu-system-i386' and expected in argv:
            return int(entry.name)
    return None


def cut_after_sector(target,log,lba,timeout):
    deadline=time.monotonic()+timeout
    while time.monotonic()<deadline:
        with target.open('rb') as image:
            image.seek(lba*512)
            written=any(image.read(512))
        if written:
            pid=qemu_for_debug_log(log)
            if pid is not None:
                os.kill(pid,signal.SIGKILL)
                return pid
        time.sleep(.002)
    return None


def run_case(input_tool,build_tool,source,reference,out,lba,boot_file):
    work=out/f'cut-lba-{lba}';work.mkdir(parents=True,exist_ok=True)
    target=work/'target.img'
    target.write_bytes(bytes(2048*512)+reference[2048*512:])
    if not any(reference[lba*512:(lba+1)*512]):
        raise ValueError(f'Reference LBA {lba} is zero and cannot trigger the cut')
    log=(work/'interrupted'/'debug.log').resolve()
    state={}
    watcher=threading.Thread(target=lambda:state.update(pid=cut_after_sector(target,log,lba,180)),daemon=True)
    watcher.start()
    command=f'I386InstallBootImage("C:/","D:/","C:{boot_file}");'
    interrupted_error=None
    try:
        input_tool.run_input(source,work/'interrupted',target_disk=target,snapshot=False,
            ram_mib=16,accel='kvm',startup_timeout=180,startup_check={
                'status':'ok','answers':[],'command_timeout':120,'commands':[(command,['1'])]})
    except Exception as error:
        interrupted_error=repr(error)
    watcher.join(timeout=1)
    if not state.get('pid') or interrupted_error is None:
        raise ValueError(f'QEMU was not cut during LBA {lba} publication: {state}')
    partial=target.read_bytes()
    if any(partial[:512]) or partial[2048*512:]!=reference[2048*512:]:
        raise ValueError('Interrupted install published LBA 0 or changed the filesystem')
    if not any(partial[lba*512:(lba+1)*512]):
        raise ValueError('Watched boot sector was not written before the power cut')
    integrity=build_tool.verify_mutated_volume(target)
    sectors=sum(any(partial[i*512:(i+1)*512]) for i in range(1,2048))
    retry=input_tool.run_input(source,work/'retry',target_disk=target,snapshot=False,
        ram_mib=16,accel='kvm',startup_timeout=180,startup_check={
            'status':'ok','answers':[],'command_timeout':120,'commands':[(command,['1'])]})
    if target.read_bytes()!=reference:
        raise ValueError('Retried installation differs from the clean reference disk')
    independent=input_tool.run_input(target,work/'independent',snapshot=True,
        ram_mib=16,accel='kvm',startup_timeout=180,startup_check={
            'status':'ok','answers':[],'command_timeout':120,'commands':[('6*7;',['42'])]})
    return {'cut_lba':lba,'interrupted_process':state['pid'],
            'interrupted_error':interrupted_error,'partial_nonzero_boot_sectors':sectors,
            'lba_zero':'blank','filesystem':integrity,'retry':retry,'independent_boot':independent,
            'result':'pass'}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source',type=Path,default=ROOT/'build/i386-kernel/gen2-guest-boot/source.img')
    parser.add_argument('--reference',type=Path,default=ROOT/'build/i386-kernel/gen2-guest-boot/target.img')
    parser.add_argument('--out',type=Path,default=ROOT/'build/i386-kernel/gen2-install-recovery')
    parser.add_argument('--boot-file',default='/Probe/Gen2.bin',
                        help='Absolute RedSea path to guest-built boot image on source disk')
    args=parser.parse_args()
    if not args.boot_file.startswith('/') or '"' in args.boot_file:
        parser.error('--boot-file must be an absolute RedSea path without quotes')
    args.out.mkdir(parents=True,exist_ok=True)
    input_tool=load_tool('i386_input',Path('tools/i386-kernel-input.py'))
    build_tool=load_tool('i386_build',Path('tools/build-i386-kernel.py'))
    source=args.out/'source.img';source.write_bytes(args.source.read_bytes())
    original=source.read_bytes();reference=args.reference.read_bytes()
    if len(original)!=32768*512 or len(reference)!=len(original):
        raise ValueError('Expected two 16 MiB RedSea disks')
    if args.boot_file not in build_tool.mutated_file_contents(source,{args.boot_file}):
        raise ValueError(f'Source disk has no guest-built {args.boot_file}')
    result={'result':'incomplete','cases':[]}
    (args.out/'result.json').unlink(missing_ok=True)
    for lba in (128,850):
        case=run_case(input_tool,build_tool,source,reference,args.out,lba,args.boot_file)
        result['cases'].append(case)
        print(f'LBA {lba}: pass, {case["partial_nonzero_boot_sectors"]} boot sectors written',flush=True)
    if source.read_bytes()!=original: raise ValueError('Installation changed source disk')
    result['source_unchanged']=True
    result['result']='pass'
    (args.out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({'result':'pass','cases':len(result['cases'])}))


if __name__=='__main__': main()
