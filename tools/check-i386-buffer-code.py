#!/usr/bin/env python3
"""Independently execute saved CmpBuf machine code as a Linux ELF32 program."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('contract', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.contract.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    paths = [source/name for name in ('buffer-code.bin', 'buffer-sizes.bin',
                                     'buffer-entries.bin', 'buffer-records.bin')]
    paths.append(Path(__file__).resolve())
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in paths}
    report = dict(result='running', input_sha256=pins,
                  scope='Independent ELF32 execution of six unrelocated production CmpBuf packets without imports or absolute relocations; native guest contract covers other cases.')
    try:
        code = paths[0].read_bytes()
        sizes = struct.unpack('<14q', paths[1].read_bytes())
        entries = struct.unpack('<14q', paths[2].read_bytes())
        rows = struct.unpack('<140q', paths[3].read_bytes())
        cases = [0,1,2,3,4,6]
        expected = [42,0x123456789ABCDEF,42,26,26,42]
        asm = ['.global _start', '.text', '_start:']
        bodies = []
        for slot, index in enumerate(cases):
            if rows[index*10+6] & ~3:
                raise ValueError('Packet needs relocation: '+str(index))
            size, entry = sizes[index], entries[index]
            if not 0 <= entry < size <= 4096:
                raise ValueError('Invalid packet bounds')
            data = code[index*4096:index*4096+size]
            if len(data) != size:
                raise ValueError('Truncated code')
            asm += [f'call packet{index}+{entry}', f'mov %eax,output+{slot*8}',
                    f'mov %edx,output+{slot*8+4}']
            bodies += [f'packet{index}:', '.byte '+','.join(map(str,data))]
        asm += ['mov $4,%eax','mov $1,%ebx','mov $output,%ecx',
                'mov $48,%edx','int $0x80','mov $1,%eax','xor %ebx,%ebx',
                'int $0x80'] + bodies + ['.bss','output:','.skip 48']
        (out/'check.s').write_text('\n'.join(asm)+'\n')
        subprocess.run(['as','--32',str(out/'check.s'),'-o',str(out/'check.o')],check=True)
        subprocess.run(['ld','-m','elf_i386',str(out/'check.o'),'-o',str(out/'check')],check=True)
        data = subprocess.check_output([str(out/'check')], timeout=10)
        (out/'results.bin').write_bytes(data)
        if data != struct.pack('<6Q',*expected):
            raise ValueError('Independent results differ: '+data.hex())
        report.update(result='pass', cases=cases, values=expected)
    except BaseException as error:
        report.update(result='fail',error=str(error) or type(error).__name__)
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])
    print('PASS independent CmpBuf ELF32 execution')


if __name__ == '__main__':
    main()
