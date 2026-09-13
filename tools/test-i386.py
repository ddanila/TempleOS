#!/usr/bin/env python3
"""Cross-compile HolyC expressions in TempleOS and execute them in protected mode.

This is a backend regression, not a complete i386 OS or a real-386 validation.
"""
import json
from pathlib import Path
import shutil
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build/i386-test'


def run(*args):
    subprocess.run(args, cwd=ROOT, check=True)


def main():
    overlay = OUT / 'overlay/Compiler/I386'
    overlay.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ROOT/'Compiler/I386/Expr.HC', overlay/'Expr.HC')
    iso = OUT/'compiler.iso'
    exports = OUT/'exports'
    run(sys.executable, 'tools/build-iso.py', '--overlay', str(OUT/'overlay'),
        '--overlay', 'tests/guest/i386', '--output', str(iso))
    run(sys.executable, 'tools/guest-run.py', str(iso), '--out', str(exports),
        '--timeout', '90')
    data = (exports/'expressions.bin').read_bytes()
    offset = count = 0
    listing = []
    # Validate only executable ranges: never disassemble record headers as code.
    allowed = {'push', 'pop', 'mov', 'add', 'adc', 'sub', 'sbb', 'and', 'or',
               'xor', 'mul', 'imul', 'neg', 'not', 'ret'}
    while True:
        size, = struct.unpack_from('<I', data, offset)
        offset += 4
        if not size:
            break
        expected, = struct.unpack_from('<Q', data, offset)
        offset += 8
        code = data[offset:offset+size]
        if len(code) != size:
            raise ValueError('Truncated generated case')
        binary = OUT/'case.bin'
        binary.write_bytes(code)
        disassembly = subprocess.check_output(['ndisasm', '-b32', str(binary)],
                                             text=True)
        for line in disassembly.splitlines():
            mnemonic = line.split()[2]
            if mnemonic not in allowed:
                raise ValueError(f'Unexpected instruction: {line}')
        listing.append(f'; Case {count}: expected {expected:016X}\n'+disassembly)
        offset += size
        count += 1
    if offset != len(data) or count != 9:
        raise ValueError('Unexpected test corpus')
    (OUT/'expressions.asm.txt').write_text('\n'.join(listing))
    # NASM -D string macro keeps the fixture independent of a fixed export path.
    disk = OUT/'runner.img'
    run('nasm', '-f', 'bin', f'-DCASES_FILE="{exports / "expressions.bin"}"',
        'tests/i386/runner.asm', '-o', str(disk))
    if disk.stat().st_size > 65*512:
        raise ValueError('Runner exceeds boot-loader transfer size')
    with disk.open('ab') as stream:
        stream.truncate(16*1024*1024)
    log = OUT/'runner.log'
    log.write_text('')
    cmd = ['qemu-system-i386', '-machine', 'pc', '-accel', 'tcg', '-cpu', '486',
           '-m', '8', '-nic', 'none', '-drive', f'file={disk},format=raw,if=ide',
           '-display', 'none', '-debugcon', f'file:{log}',
           '-device', 'isa-debug-exit,iobase=0xf4,iosize=4', '-no-reboot']
    result = subprocess.run(cmd, timeout=20)
    if result.returncode != 33 or log.read_text() != 'PASS i386 expressions\n':
        raise RuntimeError(f'Protected-mode runner failed: {log.read_text()}')
    (OUT/'result.json').write_text(json.dumps({'cases': count, 'cpu': '486',
        'ram_mib': 8, 'result': 'pass', 'scope': 'integer expression backend'}, indent=2)+'\n')
    print(f'PASS: {count} HolyC-generated i386 cases; instruction audit; rejection tests.')


if __name__ == '__main__':
    main()
