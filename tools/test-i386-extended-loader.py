#!/usr/bin/env python3
"""Exercise the extended CHS/high-memory stage with an independently built payload."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--stage',type=Path,default=ROOT/'tools/i386-extended-stage.asm')
    args=parser.parse_args()
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sources=[Path(__file__).resolve(),args.stage.resolve(),ROOT/'tools/i386-bios.inc']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in sources}
    report={'result':'fail','input_sha256':pins,'scope':'640 KiB streamed CHS payload, high-memory first/tail markers and checksum/memory rejection; not TempleOS integration or installation','cases':{}}
    assembly=out/'payload.asm'
    assembly.write_text('''bits 32
org 0x100000
db 0xE9
dd entry-($+4)
times 8-($-$$) db 0
entry:
    cmp dword [0x100000+512],0x1234A5C1
    jne fail
    cmp dword [0x100000+655360-4],0xECB749D5
    jne fail
    mov esi,message
loop_print:
    lodsb
    test al,al
    jz done
    out 0xE9,al
    jmp loop_print
fail:
    mov al,'X'
    out 0xE9,al
done:
    cli
    hlt
    jmp done
message: db 'EXTENDED LOAD PASS',10,0
times 512-($-$$) db 0
dd 0x1234A5C1
times 655360-16-($-$$) db 0
db 0xC1,0x36,0x5A,0x92,0x0F,0xB8,0xE4,0x7D,0x6A,0x03,0x8F,0x21,0xD5,0x49,0xB7,0xEC
''')
    payload=out/'payload.bin'
    subprocess.run(['nasm','-f','bin',str(assembly),'-o',str(payload)],check=True)
    raw=payload.read_bytes()
    assert len(raw)==655360
    fnv=2166136261
    for byte in raw:fnv=((fnv^byte)*16777619)&0xFFFFFFFF
    image=out/'loader.img'
    subprocess.run(['nasm','-f','bin',f'-DKERNEL_FILE="{payload}"',f'-DPAYLOAD_FNV={fnv}','-l',str(out/'loader.lst'),str(args.stage.resolve()),'-o',str(image)],cwd=ROOT,check=True)
    built=image.read_bytes()
    cases=[('valid',built,8,'EXTENDED LOAD PASS\n'),('checksum',built[:-1]+bytes([built[-1]^1]),8,'B'),('insufficient-memory',built,1,'B')]
    # Metadata is in the stage at disk sector one, independent of the payload.
    for name,offset,value in [('bad-magic',16,0),('bad-version',20,2),
                              ('short-length',24,7),('oversized-length',24,2039*512+1),
                              ('bad-base',28,0x110000)]:
        damaged=bytearray(built)
        damaged[512+offset:512+offset+4]=value.to_bytes(4,'little')
        cases.append((name,bytes(damaged),8,'B'))
    try:
        for name,body,ram,expected in cases:
            disk=out/(name+'.img');disk.write_bytes(body+bytes(16*1024*1024-len(body)))
            digest=sha(disk);log=out/(name+'.debug.log')
            with (out/(name+'.qemu.log')).open('wb') as stderr:
                process=subprocess.Popen(['qemu-system-i386','-machine','pc','-accel','tcg','-cpu','486,-fpu','-m',str(ram),'-nic','none','-drive',f'file={disk},format=raw,if=ide','-snapshot','-display','none','-no-reboot','-debugcon',f'file:{log}'],stdout=subprocess.DEVNULL,stderr=stderr)
                try:
                    deadline=time.monotonic()+60
                    while time.monotonic()<deadline:
                        text=log.read_text() if log.exists() else ''
                        if name=='valid' and text.endswith(('B','X')):raise RuntimeError(name+' boot failure: '+text)
                        if expected in text:break
                        if process.poll() is not None:raise RuntimeError(name+' QEMU terminated: '+text)
                        time.sleep(.1)
                    else:raise TimeoutError(name+' expected '+repr(expected)+'; got '+repr(text))
                    if sha(disk)!=digest:raise ValueError('Snapshot changed '+name+' disk')
                    report['cases'][name]={'result':'pass','disk_sha256':digest,'ram_mib':ram,'log':text}
                finally:
                    process.terminate()
                    try:process.wait(timeout=5)
                    except subprocess.TimeoutExpired:process.kill();process.wait()
        if any(sha(Path(p))!=digest for p,digest in pins.items()):raise ValueError('Qualification sources changed')
        report.update(result='pass',payload_bytes=len(raw),payload_sha256=sha(payload),load_base=0x100000)
    except Exception as error:
        report['error']=str(error);raise
    finally:(out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
