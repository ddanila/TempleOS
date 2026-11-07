#!/usr/bin/env python3
"""Execute target statements emitted through production CmpI386Buf/LexStmt2Bin."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]
EXPECTED=[42,0x123456789ABCDEF,42,42,0x400E000000000000,((0x123456789ABCDEF<<13)^0x7FEDCBA987654321)&((1<<64)-1)]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    paths=[Path(__file__).resolve(),ROOT/'tests/guest/i386-cross-statement/Once.HC',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',ROOT/'build/rebuild-test/result.json',ROOT/'build/rebuild-test/overlay/Compiler/Compiler.BIN',ROOT/'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C']
    paths+=sorted(p for base in ['Compiler','Kernel'] for p in (ROOT/base).rglob('*') if p.suffix in ['.HC','.HH'])
    pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='Production cross-compiler top-level statements via actual CmpI386Buf/LexStmt2Bin/COCCompile and independent ELF32 execution; isolated AOT records retained, no heap or native normal-API qualification.')
    try:
        bootstrap=json.loads((ROOT/'build/rebuild-test/result.json').read_text())
        for name,digest in bootstrap['source_sha256'].items():
            if name.startswith(('Compiler/','Kernel/')) and sha(ROOT/name)!=digest:raise ValueError('Stale bootstrap: '+name)
        iso=out/'compiler.iso'
        subprocess.run(['python3','tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay','tests/guest/i386-cross-statement','--output',str(iso)],cwd=ROOT,check=True)
        subprocess.run(['python3','tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--timeout','180','--qmp-stdio'],cwd=ROOT,check=True)
        log=(out/'guest/debug.log').read_text()
        if log.count('CROSS REJECT unsupported instruction\n')!=1:raise ValueError('Missing backend rejection/recovery')
        rejection=(out/'guest/rejected-statement.DD').read_bytes()
        if b'i386 COC failure at opcode 64' not in rejection:raise ValueError('Rejection did not reach target backend CLFlush')
        rows=re.findall(r'^CROSS STATEMENT (\d+) ([0-9A-F]+) ([0-9A-F]+)$',log,re.M)
        if len(rows)!=len(EXPECTED):raise ValueError('Missing statement records')
        asm=['.global _start','.text','_start:'];bodies=[];records=[]
        for i,(index,offset,size) in enumerate(rows):
            if int(index)!=i:raise ValueError('Statement order differs')
            data=(out/f'guest/cross-statement-{i}.bin').read_bytes();offset=int(offset,16)
            if len(data)!=int(size,16) or not 0<=offset<len(data):raise ValueError('Invalid statement bounds')
            asm += [f'call statement{i}+{offset}',f'mov %eax,output+{i*8}',f'mov %edx,output+{i*8+4}']
            bodies += [f'statement{i}:','.byte '+','.join(str(b) for b in data)]
            records.append(dict(index=i,entry=offset,bytes=len(data),sha256=hashlib.sha256(data).hexdigest()))
        asm += ['mov $4,%eax','mov $1,%ebx','mov $output,%ecx',f'mov ${len(EXPECTED)*8},%edx','int $0x80','mov $1,%eax','xor %ebx,%ebx','int $0x80']+bodies+['.bss','output:',f'.skip {len(EXPECTED)*8}']
        (out/'check.s').write_text('\n'.join(asm)+'\n')
        subprocess.run(['as','--32',str(out/'check.s'),'-o',str(out/'check.o')],check=True)
        subprocess.run(['ld','-m','elf_i386',str(out/'check.o'),'-o',str(out/'check')],check=True)
        data=subprocess.check_output([str(out/'check')]);(out/'results.bin').write_bytes(data)
        if data!=struct.pack('<6Q',*EXPECTED):raise ValueError('Emitted production statement results differ: '+data.hex())
        report.update(result='pass',unsupported_instruction_rejected=True,records=records,values=list(struct.unpack('<6Q',data)))
    except BaseException as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])
if __name__=='__main__':main()
