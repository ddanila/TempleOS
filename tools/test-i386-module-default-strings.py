#!/usr/bin/env python3
"""Require relocatable default strings and inferred class names in native modules."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/'tests/guest/i386-module-default-strings/Contract.HC'



def execute_at_two_bases(module, out):
    """Execute actual emitted i386 code in an ELF, at two distinct load addresses."""
    size,count,records=struct.unpack_from('<3I',module,16)
    rows=[struct.unpack_from('<4I',module,records+16*i) for i in range(count)]
    exports={module[n:n+l].decode():o for k,o,n,l in rows if k==1}
    code=bytearray(module[32:32+size])
    for kind,offset,name,length in rows:
        if kind==2:
            target=module[name:name+length].decode()
            if target not in exports:raise ValueError('Unexpected external import '+target)
            struct.pack_into('<i',code,offset,exports[target]-offset-4)
        elif kind not in (1,4):raise ValueError('Unexpected fixture relocation kind')
    (out/'relocated-code.bin').write_bytes(code)
    asm=['BITS 32','global _start','section .text','_start:']
    cases=[('ClassName',b'UniqueModuleClassName\0'),('DefaultText',b'module-default-string-value\0')]
    for image in ('image1','image2'):
        for index,(name,value) in enumerate(cases):
            asm += [f'call {image}+{exports[name]}','test edx,edx','jnz fail',
                    f'cmp eax,{image}','jb fail',f'cmp eax,{image}_end','jae fail',
                    'mov esi,eax',f'mov edi,expected{index}',f'mov ecx,{len(value)}',
                    'cld','repe cmpsb','jne fail']
    asm += ['xor ebx,ebx','jmp done','fail:','mov ebx,1','done:','mov eax,1','int 0x80']
    for index,(_,value) in enumerate(cases):asm += [f'expected{index}: db '+','.join(map(str,value))]
    for image in ('image1','image2'):
        asm += ['align 4096',image+':','incbin "relocated-code.bin"',image+'_end:']
    (out/'execute.asm').write_text('\n'.join(asm)+'\n')
    subprocess.run(['nasm','-f','elf32','execute.asm','-o','execute.o'],cwd=out,check=True)
    subprocess.run(['ld','-m','elf_i386','execute.o','-o','execute'],cwd=out,check=True)
    subprocess.run([str(out/'execute')],cwd=out,check=True,timeout=10)
    return dict(calls=4,load_addresses=2,scope='Pure emitted fixture functions in Linux i386 ELF; not native OS loader qualification')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    image,out=args.disk.resolve(),args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[image,FIXTURE,Path(__file__).resolve()]+[ROOT/name for name in (
        'tools/test-i386-timeclock-welcome.py','tools/package-i386-native-image.py',
        'tools/build-i386-kernel.py','tools/test-i386-retained-build.py')]
    pins={str(p):sha(p) for p in inputs}
    report={'result':'running','scope':'Two native module builds with heap perturbation; exact bytes and embedded default-string data. Includes emitted i386 execution at two load addresses; not native loader or whole-provider generation qualification.',
            'input_sha256':pins}
    try:
        disk=out/'working.img'
        report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
            image,disk,additions={'/Defaults.HC':FIXTURE.read_bytes()})
        command='I386BuildModule("C:/Defaults.HC","C:/Probe/Defaults1.t32m",TRUE);'
        runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](
            disk,out/'guest',[command,'U8 *default_pad=MAlloc(65536);',command.replace('Defaults1.t32m','Defaults2.t32m'),'Free(default_pad);','6*7;'],64,False,key_delay=.05,command_timeout=600,allow_inner_rejection=True,accel='kvm')
        log=(out/'guest/debug.log').read_text()
        if 'BUILD MODULE REJECT ' in log:raise ValueError('Native module compilation rejected; inspect guest debug log')
        paths={'/Defaults.HC','/Probe/Defaults1.t32m','/Probe/Defaults2.t32m'}
        files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,paths)
        if files['/Defaults.HC']!=FIXTURE.read_bytes():raise ValueError('Delivered fixture changed')
        module=files['/Probe/Defaults1.t32m']
        count,exports=runpy.run_path(str(ROOT/'tools/test-i386-retained-build.py'))['exports_of'](module)
        (out/'first.t32m').write_bytes(module)
        second=files['/Probe/Defaults2.t32m'];(out/'second.t32m').write_bytes(second)
        payload,count,records=struct.unpack_from('<3I',module,16)
        ranges=[(offset,name) for kind,offset,name,length in
                (struct.unpack_from('<4I',module,records+16*i) for i in range(count)) if kind==4]
        checks={}
        for value in (b'UniqueModuleClassName\0',b'module-default-string-value\0'):
            positions=[i for i in range(payload-len(value)+1) if module[32+i:32+i+len(value)]==value]
            checks[value[:-1].decode()]=any(lo<=i and i+len(value)<=lo+length for i in positions for lo,length in ranges)
        report.update(embedded_default_strings=checks,byte_identical=module==second)
        if not all(checks.values()):raise ValueError('Default string missing from module-owned data')
        if module!=second:raise ValueError('Module bytes depend on prior heap placement')
        if not {'ClassName','DefaultText'}.issubset(exports):raise ValueError('Missing probe exports')
        report['execution']=execute_at_two_bases(module,out)
        report.update(result='pass',module_sha256=hashlib.sha256(module).hexdigest(),records=count,exports=exports)
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(Path(p).is_file() and sha(Path(p))==digest for p,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
