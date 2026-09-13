#!/usr/bin/env python3
"""Compile the shared module validator with HolyC and execute it as i386 code."""
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'build/i386-module-check'


def run(*args):
    subprocess.run(args, cwd=ROOT, check=True)


def main():
    manifest = json.loads((ROOT/'build/rebuild-test/result.json').read_text())
    for name, digest in manifest['source_sha256'].items():
        if name.startswith(('Compiler/', 'Kernel/')):
            if hashlib.sha256((ROOT/name).read_bytes()).hexdigest() != digest:
                raise ValueError(f'Rerun tools/test-rebuild.py: changed {name}')
    for name, path in [('Compiler.BIN', 'Compiler/Compiler.BIN'),
                       ('Kernel.BIN', '0000Boot/0000Kernel.BIN.C')]:
        binary = ROOT/'build/rebuild-test/overlay'/path
        if hashlib.sha256(binary.read_bytes()).hexdigest() != manifest['generations'][-1][name]:
            raise ValueError(f'Rerun tools/test-rebuild.py: stale {name}')
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT/'result.json').unlink(missing_ok=True)
    iso = OUT/'validator.iso'
    exports = OUT/'exports'
    run(sys.executable, 'tools/build-iso.py', '--overlay', 'build/rebuild-test/overlay',
        '--overlay', 'tests/guest/i386-module-check', '--output', str(iso))
    run(sys.executable, 'tools/guest-run.py', str(iso), '--out', str(exports), '--timeout', '90')
    code = (exports/'validator.bin').read_bytes()
    starts = sorted(int(line.split()[2],16) for line in (exports/'debug.log').read_text().splitlines()
                    if line.startswith('RANGE '))
    if len(starts)!=2 or starts[0]!=0:
        raise ValueError('Unexpected validator function boundaries')
    allowed = {'push','pop','mov','movzx','movsx','add','adc','sub','sbb','and','or','xor',
               'neg','not','mul','imul','div','dec','rcl','shl','shr','sar','shld','shrd',
               'cmp','test','call','ret','jmp','jz','jnz','jc','jnc','ja','jna','jns',
               'setz','setnz','setl','setnl','setg','setng','setc','setnc','seta','setna','cdq'}
    listing=[]
    for start,end in zip(starts,starts[1:]+[len(code)]):
        body=code[start:end]
        (OUT/'body.bin').write_bytes(body)
        lines=subprocess.check_output(['ndisasm','-b32',str(OUT/'body.bin')],text=True).splitlines()
        code_end=None
        for line in lines:
            parts=line.split()
            if parts[2] not in allowed:
                raise ValueError(f'Unexpected instruction: {line}')
            listing.append(line)
            if parts[2]=='ret':
                code_end=int(parts[0],16)+len(parts[1])//2
                break
        if code_end is None or len(body)-code_end>7 or any(body[code_end:]):
            raise ValueError('Invalid function padding')
    (OUT/'validator.asm.txt').write_text('\n'.join(listing)+'\n')
    base=(exports/'sample.t32m').read_bytes()
    roff,soff=struct.unpack_from('<II',base,24)
    records=[struct.unpack_from('<4I',base,i) for i in range(roff,soff,16)]
    imp=next(i for i,r in enumerate(records) if r[0]==2)
    patch=roff+imp*16
    cases=[('valid',base,len(base),1,0),('null',base,len(base),0,1),
           ('short-header',base,31,0,0),('truncated',base,len(base)-1,0,0),
           ('negative-length',base,-1,0,0),('wide-length',base,1<<32,0,0)]
    mutations=[('magic',0,'I',0),('version',4,'H',3),('cpu',6,'B',6),
               ('pointer-width',7,'B',8),('abi',8,'I',2),('total-size',12,'I',len(base)+1),
               ('code-size',16,'I',0xFFFFFFF8),('record-count',20,'I',0x10000000),
               ('record-offset',24,'I',0),('string-offset',28,'I',0xFFFFFFFF),
               ('record-kind',patch,'I',99),('patch-offset',patch+4,'I',0xFFFFFFFF),
               ('name-offset',patch+8,'I',0xFFFFFFFF),('empty-name',patch+12,'I',0),
               ('name-terminator',records[imp][2]+records[imp][3],'B',1),
               ('call-opcode',32+records[imp][1]-1,'B',0x90),
               ('call-displacement',32+records[imp][1],'B',1)]
    for name,offset,fmt,value in mutations:
        data=bytearray(base)
        struct.pack_into('<'+fmt,data,offset,value)
        cases.append((name,bytes(data),len(data),0,0))
    duplicate=bytearray(base[:roff])
    for kind,offset,name,n in records+[records[imp]]:
        duplicate+=struct.pack('<4I',kind,offset,name+16,n)
    duplicate+=base[soff:]
    struct.pack_into('<I',duplicate,12,len(duplicate))
    struct.pack_into('<I',duplicate,20,len(records)+1)
    struct.pack_into('<I',duplicate,28,soff+16)
    cases.append(('duplicate-patch',bytes(duplicate),len(duplicate),0,0))
    empty=bytearray(base[:roff])
    struct.pack_into('<I',empty,12,len(empty))
    struct.pack_into('<I',empty,20,0)
    struct.pack_into('<I',empty,28,roff)
    cases.append(('no-records',bytes(empty),len(empty),1,0))
    # Build a v2 fixture with explicitly classified data and a named data export.
    def module(payload, entries):
        strings = bytearray()
        table = bytearray()
        string_base = 32+len(payload)+16*len(entries)
        for kind, offset, name in entries:
            if kind == 4:
                table += struct.pack('<4I', kind, offset, name, 0)
            else:
                encoded = name.encode('ascii')
                table += struct.pack('<4I', kind, offset, string_base+len(strings), len(encoded))
                strings += encoded+b'\0'
        header = bytearray(base[:32])
        struct.pack_into('<5I', header, 12, string_base+len(strings), len(payload),
                         len(entries), 32+len(payload), string_base)
        return bytes(header+payload+table+strings)

    entries = [(kind, offset, base[name:name+n].decode('ascii'))
               for kind,offset,name,n in records]
    payload = base[32:roff]
    data_entries = entries+[(4,len(payload),8),(3,len(payload),'State')]
    with_data = module(payload+b'\0'*8, data_entries)
    cases.append(('valid-data',with_data,len(with_data),1,0))
    for name, replacement in [
            ('empty-data-range', entries+[(4,len(payload),0),(3,len(payload),'State')]),
            ('wide-data-range', entries+[(4,len(payload),0xFFFFFFFF),(3,len(payload),'State')]),
            ('overlap-data-ranges', data_entries+[(4,len(payload)+1,1)]),
            ('data-export-outside-range', entries+[(4,len(payload),8),(3,0,'State')]),
            ('function-export-in-data', data_entries+[(1,len(payload),'Fake')]),
            ('patch-in-data', entries+[(4,records[imp][1]-1,5)])]:
        bad = module(payload+b'\0'*8,replacement)
        cases.append((name,bad,len(bad),0,0))
    address_payload = bytearray(payload)
    address_payload[records[imp][1]-1] = 0x05
    address_entries = [(5 if kind==2 else kind,offset,name) for kind,offset,name in entries]
    address_module = module(address_payload,address_entries)
    cases.append(('address-import',address_module,len(address_module),1,0))
    bad = module(payload,address_entries)
    cases.append(('address-import-opcode',bad,len(bad),0,0))
    legacy = bytearray(base)
    struct.pack_into('<H',legacy,4,1)
    cases.append(('legacy-format',bytes(legacy),len(legacy),0,0))
    data=b''.join(struct.pack('<IqII',len(payload),size,expected,null)+payload
                  for _,payload,size,expected,null in cases)+struct.pack('<I',0)
    table=OUT/'cases.bin'
    table.write_bytes(data)
    disk=OUT/'runner.img'
    run('nasm','-f','bin',f'-DVALIDATOR_FILE="{exports / "validator.bin"}"',
        f'-DCASES_FILE="{table}"','tests/i386/module-check.asm','-o',str(disk))
    if disk.stat().st_size>129*512:
        raise ValueError('Runner exceeds BIOS transfer size')
    with disk.open('ab') as stream:
        stream.truncate(16*1024*1024)
    log=OUT/'runner.log'
    log.write_text('')
    cmd=['qemu-system-i386','-machine','pc','-accel','tcg','-cpu','486','-m','8','-nic','none',
         '-drive',f'file={disk},format=raw,if=ide','-display','none','-debugcon',f'file:{log}',
         '-device','isa-debug-exit,iobase=0xf4,iosize=4','-no-reboot']
    result=subprocess.run(cmd,timeout=20)
    if result.returncode!=33 or log.read_text()!='PASS i386 module validator\n':
        raise RuntimeError(f'Target validator failed: {log.read_text()}')
    (OUT/'result.json').write_text(json.dumps({'result':'pass','cases':[c[0] for c in cases],
        'cpu':'486','ram_mib':8,'scope':'shared module validator executed as i386 code'},indent=2)+'\n')
    print(f'PASS: shared module validator executed {len(cases)} target cases.')


if __name__=='__main__':
    main()
