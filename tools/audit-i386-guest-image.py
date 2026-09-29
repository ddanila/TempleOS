#!/usr/bin/env python3
"""Audit executable regions of a guest-built, installed i386 image."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]


def load(name,path):
    spec=importlib.util.spec_from_file_location(name,ROOT/path)
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source',type=Path,default=ROOT/'build/i386-kernel/gen2-guest-boot/source.img')
    parser.add_argument('--installed',type=Path,default=ROOT/'build/i386-kernel/gen2-guest-boot/target.img')
    parser.add_argument('--stage-listing',type=Path,default=ROOT/'build/i386-kernel/kernel-stage.lst')
    parser.add_argument('--out',type=Path,default=ROOT/'build/i386-kernel/gen2-instruction-audit')
    parser.add_argument('--kernel-module-path',default='/Probe/Gen2Kernel.t32m')
    parser.add_argument('--flat-path',default='/Probe/Gen2.bin')
    parser.add_argument('--guest-compiler-template',action='store_true')
    args=parser.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    build=load('i386_build',Path('tools/build-i386-kernel.py'))
    boot=load('i386_boot_audit',Path('tools/audit-i386-boot.py'))
    names=build.DISK_MODULES
    wanted={args.kernel_module_path,args.flat_path}|{
        f'/Modules/I386/{name}.t32m' for name in names[1:]}
    files=build.mutated_file_contents(args.source,wanted)
    if set(files)!=wanted: raise ValueError(f'Missing installed source modules: {wanted-set(files)}')
    exports=args.out/'exports';exports.mkdir(exist_ok=True)
    (exports/'Kernel.t32m').write_bytes(files[args.kernel_module_path])
    flat=files[args.flat_path]
    (exports/'Kernel32.BIN').write_bytes(flat)
    for name in names[1:]:
        (exports/f'{name}.t32m').write_bytes(files[f'/Modules/I386/{name}.t32m'])
    installed=args.installed.read_bytes()
    if len(installed)!=32768*512 or installed[512+4096:512+4096+len(flat)]!=flat:
        raise ValueError('Installed boot payload differs from the guest-built flat image')
    filesystem=build.verify_mutated_volume(args.installed)
    build.audit(exports,args.out,guest_compiler_template=args.guest_compiler_template)
    boot_result=boot.audit(installed,args.stage_listing.read_text())
    result={'result':'pass','flat_bytes':len(flat),
            'flat_sha256':hashlib.sha256(flat).hexdigest(),
            'modules':{name:hashlib.sha256((exports/f'{name}.t32m').read_bytes()).hexdigest()
                       for name in names},
            'linked_module_executable_ranges':'386 instruction allowlist pass',
            'boot':boot_result,'installed_payload':'matches guest-built flat image',
            'filesystem':filesystem}
    (args.out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f'PASS: guest-built 386 executable audit, {len(flat)} linked bytes')


if __name__=='__main__': main()
