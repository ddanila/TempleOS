#!/usr/bin/env python3
"""Boot the 386 DVD loader with synthetic stage2 payloads and rejection cases."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import time
ROOT=Path(__file__).resolve().parents[1]

def iso_image(loader,payload,shift):
    data=bytearray((33+(len(payload)+shift*512+2047)//2048)*2048)
    for sector,kind in [(16,1),(17,0),(19,255)]:
        data[sector*2048:sector*2048+7]=bytes([kind])+b'CD001\x01'
    data[17*2048+7:17*2048+30]=b'EL TORITO SPECIFICATION\0'
    struct.pack_into('<I',data,17*2048+71,20)
    cat=bytearray(2048);cat[0]=1;struct.pack_into('<H',cat,30,0xAA55)
    struct.pack_into('<H',cat,28,-sum(struct.unpack('<16H',cat[:32]))&65535)
    struct.pack_into('<BBHBBHI',cat,32,0x88,0,0,0,0,4,21)
    data[20*2048:21*2048]=cat;data[21*2048:22*2048]=loader
    at=32*2048+shift*512;data[at:at+len(payload)]=payload
    return data

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True);source=ROOT/'tools/i386-dvd-stage.asm'
    pins={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in [source,Path(__file__).resolve()]}
    report=dict(result='running',input_sha256=pins,cases=[],scope='TCG 486 without FPU, real BIOS DVD reads, all four 512-byte alignments, payload bounds and register handoff; synthetic payload, not complete OS CD boot')
    (out/source.name).write_bytes(source.read_bytes())
    try:
        subprocess.run(['nasm','-f','bin',str(source),'-o',str(out/'stage1.bin')],check=True)
        raw=(out/'stage1.bin').read_bytes();assert len(raw)==2048 and raw[16:20]==b'I3CD'
        report['stage1_sha256']=hashlib.sha256(raw).hexdigest()
        cases=[(f'shift{shift}-{size}',shift,size,None) for shift in range(4) for size in [4097,285*2048-shift*512]]
        cases += [('zero-count',0,4097,'zero'),('oversize',0,4097,'large'),('invalid-shift',0,4097,'shift'),('read-error',0,4097,'read')]
        for name,shift,size,bad in cases:
            case=out/name;case.mkdir();asm=case/'stage2.asm'
            asm.write_text(f'''bits 16
org 0
    cmp eax,{(shift<<16)|4}
    jne failure
    cmp ebx,32
    jne failure
    mov ax,cs
    cmp ax,0x07C0
    jne failure
    mov ds,ax
    mov si,padding
    mov bx,padding
    ; Verify every payload byte after code, including beyond 64 KiB.
    mov edx,{size}-padding
next_byte:
    cmp byte [si],0xA7
    jne failure
    inc si
    jnz same_segment
    mov ax,ds
    add ax,0x1000
    mov ds,ax
same_segment:
    dec edx
    jnz next_byte
    mov al,'P'
    out 0xE9,al
    jmp halt
failure:
    mov al,'F'
    out 0xE9,al
halt:
    cli
    hlt
    jmp halt
padding:
    times {size}-($-$$) db 0xA7
''')
            subprocess.run(['nasm','-f','bin',str(asm),'-o',str(case/'stage2.bin')],check=True)
            payload=(case/'stage2.bin').read_bytes();loader=bytearray(raw);blocks=(size+shift*512+2047)//2048
            struct.pack_into('<IHH',loader,20,32,blocks,shift)
            if bad=='zero':struct.pack_into('<H',loader,24,0)
            if bad=='large':struct.pack_into('<H',loader,24,286)
            if bad=='shift':struct.pack_into('<H',loader,26,4)
            if bad=='read':struct.pack_into('<I',loader,20,0x100000)
            iso=case/'probe.iso';iso.write_bytes(iso_image(loader,payload,shift));log=case/'debug.log'
            cmd=['qemu-system-i386','-machine','pc','-accel','tcg','-cpu','486,-fpu','-m','8','-nic','none','-display','none','-monitor','none','-serial','none','-no-reboot','-drive',f'file={iso},format=raw,media=cdrom,if=ide,index=2','-boot','d','-debugcon',f'file:{log}']
            (case/'command.json').write_text(json.dumps(cmd,indent=2)+'\n')
            with (case/'qemu.log').open('w') as err:
                proc=subprocess.Popen(cmd,stdout=err,stderr=err)
                try:
                    deadline=time.monotonic()+30
                    while proc.poll() is None and time.monotonic()<deadline:
                        if log.exists() and log.stat().st_size:break
                        time.sleep(.1)
                    actual=log.read_text() if log.exists() else ''
                    expected='R' if bad=='read' else ('V' if bad else 'P')
                    if actual!=expected:raise ValueError(f'{name}: expected {expected!r}, got {actual!r}')
                finally:
                    if proc.poll() is None:proc.terminate()
                    proc.wait(timeout=10)
            report['cases'].append(dict(name=name,result='pass',marker=actual,shift=shift,bytes=size))
            print('PASS',name,flush=True)
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(hashlib.sha256(Path(p).read_bytes()).hexdigest()==h for p,h in pins.items())
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if not report['inputs_unchanged']:raise ValueError('Inputs changed')
if __name__=='__main__':main()
