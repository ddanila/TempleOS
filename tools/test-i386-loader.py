#!/usr/bin/env python3
"""Execute the shared module loader and its loaded code inside an i386 guest."""
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'build/i386-loader-test'


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
    # Regenerate input modules with this source/compiler and audit their code.
    run(sys.executable, 'tools/test-i386.py', '--data')
    fixtures = ROOT/'build/i386-data-test/exports'
    inputs = {}
    for line in (fixtures/'debug.log').read_text().splitlines():
        match = re.match(r'EXPORT (data-(\d+)-(\d+)\.t32m) ',line)
        if match:
            name, case, order = match.groups()
            inputs.setdefault(int(case), {})[int(order)] = (fixtures/name).read_bytes()
    corpus = (fixtures/'expressions.bin').read_bytes()
    cases = []
    offset = 0
    while (size := struct.unpack_from('<I',corpus,offset)[0]):
        expected = struct.unpack_from('<Q',corpus,offset+4)[0]
        modules = inputs[len(cases)]
        cases.append((f'data-{len(cases)}', [modules[i] for i in sorted(modules)], expected, 0))
        offset += 28+size
    if offset+4 != len(corpus) or len(cases)!=16:
        raise ValueError('Unexpected data corpus')
    consumer, provider = cases[10][1]
    bad = bytearray(consumer)
    bad[0] ^= 1
    cases += [('bad-magic',[bytes(bad),provider],0,1),
              ('truncated',[consumer[:-1],provider],0,1),
              ('unresolved',[consumer],0,1),
              ('duplicate-export',[consumer,provider,provider],0,1),
              ('missing-entry',[provider],0,1)]
    def function_to_data(module, symbol):
        module = bytearray(module)
        roff, soff = struct.unpack_from('<II',module,24)
        records = [(pos,struct.unpack_from('<4I',module,pos)) for pos in range(roff,soff,16)]
        data_offset = next(record[1] for _,record in records if record[0]==4)
        for pos,(kind,offset,name,n) in records:
            if kind==1 and module[name:name+n].decode()==symbol:
                struct.pack_into('<II',module,pos,3,data_offset)
                return bytes(module)
        raise ValueError('Missing function fixture')
    cases += [('data-entry',[function_to_data(cases[0][1][0],'Main')],0,1),
              ('call-data',[consumer,function_to_data(provider,'Add')],0,1)]
    iso = OUT/'loader.iso'
    exports = OUT/'exports'
    run(sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay',
        '--overlay','tests/guest/i386-loader','--output',str(iso))
    run(sys.executable,'tools/guest-run.py',str(iso),'--out',str(exports),'--timeout','90')
    code = (exports/'loader.bin').read_bytes()
    log = (exports/'debug.log').read_text().splitlines()
    starts = sorted(int(line.split()[2],16) for line in log if line.startswith('RANGE '))
    regions = [tuple(int(v,16) for v in line.split()[2:]) for line in log if line.startswith('DATA ')]
    if not starts or len(starts)!=len(set(starts)) or code[0]!=0xE9 or any(code[5:8]):
        raise ValueError('Invalid loader boundaries')
    if 5+struct.unpack_from('<i',code,1)[0] not in starts:
        raise ValueError('Invalid loader entry')
    covered = bytearray(len(code))
    covered[:8] = b'P'*8
    for begin,length in regions:
        if begin<8 or length<=0 or begin+length>len(code) or any(covered[begin:begin+length]):
            raise ValueError('Invalid loader data')
        covered[begin:begin+length] = b'D'*length
    boundaries = sorted(set(starts+[begin for begin,_ in regions]+[len(code)]))
    allowed = {'push','pop','mov','movzx','movsx','add','adc','sub','sbb','and','or','xor',
               'in','out','neg','not','mul','imul','div','dec','rcl','shl','shr','sar','shld','shrd',
               'cmp','test','call','ret','jmp','jz','jnz','jc','jnc','ja','jna','jns',
               'setz','setnz','setl','setnl','setg','setng','setc','setnc','seta','setna','cdq'}
    listing = []
    for start in starts:
        end = next(pos for pos in boundaries if pos>start)
        if any(covered[start:end]):
            raise ValueError('Loader code overlaps data')
        covered[start:end] = b'C'*(end-start)
        body = code[start:end]
        (OUT/'body.bin').write_bytes(body)
        lines = subprocess.check_output(['ndisasm','-b32',str(OUT/'body.bin')],text=True).splitlines()
        code_end = None
        for line in lines:
            parts = line.split()
            if parts[2] not in allowed:
                raise ValueError(f'Unexpected instruction: {line}')
            listing.append(line)
            if parts[2]=='ret':
                code_end = int(parts[0],16)+len(parts[1])//2
                break
        if code_end is None or len(body)-code_end>7 or any(body[code_end:]):
            raise ValueError('Invalid loader function padding')
    gap = 0
    for i,marker in enumerate(covered):
        gap = 0 if marker else gap+1
        if not marker and (code[i] or gap>7):
            raise ValueError('Unclassified loader bytes')
    (OUT/'loader.asm.txt').write_text('\n'.join(listing)+'\n')
    table = bytearray()
    for _,modules,expected,mode in cases:
        sizes = [len(module) for module in modules]
        packet = struct.pack('<IIQ3I',mode,len(modules),expected,*(sizes+[0]*(3-len(sizes))))+b''.join(modules)
        table += struct.pack('<IqII',len(packet),len(packet),0,0)+packet
    table += struct.pack('<I',0)
    (OUT/'cases.bin').write_bytes(table)
    disk = OUT/'runner.img'
    run('nasm','-DBOOT_SECTORS=256','-f','bin',f'-DVALIDATOR_FILE="{exports / "loader.bin"}"',
        f'-DCASES_FILE="{OUT / "cases.bin"}"','-DTEST_NAME="i386 module loader"',
        'tests/i386/module-check.asm','-o',str(disk))
    if disk.stat().st_size>257*512:
        raise ValueError('Loader runner exceeds BIOS transfer size')
    with disk.open('ab') as stream:
        stream.truncate(16*1024*1024)
    log = OUT/'runner.log'
    log.write_text('')
    result = subprocess.run(['qemu-system-i386','-machine','pc','-accel','tcg','-cpu','486',
        '-m','8','-nic','none','-drive',f'file={disk},format=raw,if=ide','-display','none',
        '-debugcon',f'file:{log}','-device','isa-debug-exit,iobase=0xf4,iosize=4','-no-reboot'],timeout=30)
    if result.returncode!=33 or log.read_text()!='PASS i386 module loader\n':
        raise RuntimeError(f'Native loader failed: {log.read_text()}')
    (OUT/'result.json').write_text(json.dumps({'result':'pass','cases':[c[0] for c in cases],
        'cpu':'486','ram_mib':8,'scope':'native module loading, heap allocation, execution, exhaustion, release and reuse'},indent=2)+'\n')
    print(f'PASS: native i386 loader executed {len(cases)} cases.')


if __name__=='__main__':
    main()
