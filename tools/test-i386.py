#!/usr/bin/env python3
"""Cross-compile HolyC expressions in TempleOS and execute them in protected mode.

This is a backend regression, not a complete i386 OS or a real-386 validation.
"""
import argparse
import hashlib
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
    global OUT
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--functions', action='store_true',
                        help='Test normal function compilation using test-rebuild.py output')
    functions = parser.parse_args().functions
    kind = 'functions' if functions else 'expressions'
    if functions:
        OUT = ROOT/'build/i386-functions-test'
        manifest = json.loads((ROOT/'build/rebuild-test/result.json').read_text())
        for name, digest in manifest['source_sha256'].items():
            if name.startswith(('Compiler/', 'Kernel/')):
                if hashlib.sha256((ROOT/name).read_bytes()).hexdigest() != digest:
                    raise ValueError(f'Rerun tools/test-rebuild.py: changed source {name}')
        for name, path in [('Compiler.BIN', 'Compiler/Compiler.BIN'),
                           ('Kernel.BIN', '0000Boot/0000Kernel.BIN.C')]:
            binary = ROOT/'build/rebuild-test/overlay'/path
            if hashlib.sha256(binary.read_bytes()).hexdigest() != manifest['generations'][-1][name]:
                raise ValueError(f'Rerun tools/test-rebuild.py: stale {name}')
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT/'result.json').unlink(missing_ok=True)
    overlay = OUT / 'overlay/Compiler/I386'
    overlay.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ROOT/'Compiler/I386/Expr.HC', overlay/'Expr.HC')
    iso = OUT/'compiler.iso'
    exports = OUT/'exports'
    build = [sys.executable, 'tools/build-iso.py', '--overlay', str(OUT/'overlay')]
    if functions:
        build += ['--overlay', 'build/rebuild-test/overlay']
    build += ['--overlay', 'tests/guest/i386-functions' if functions else 'tests/guest/i386',
              '--output', str(iso)]
    run(*build)
    run(sys.executable, 'tools/guest-run.py', str(iso), '--out', str(exports),
        '--timeout', '90')
    ranges = {}
    if functions:
        for line in (exports/'debug.log').read_text().splitlines():
            if line.startswith('RANGE '):
                _, case, start = line.split()
                ranges.setdefault(int(case), []).append(int(start, 16))
    data = (exports/'expressions.bin').read_bytes()
    offset = count = 0
    listing = []
    # Validate only executable ranges: never disassemble record headers as code.
    allowed = {'push', 'pop', 'mov', 'add', 'adc', 'sub', 'sbb', 'and', 'or',
               'xor', 'mul', 'imul', 'neg', 'not', 'ret', 'movsx', 'movzx', 'cdq', 'jmp',
               'cmp', 'jz', 'jnz', 'setz', 'setnz', 'setl', 'setnl', 'setg',
               'setng', 'setc', 'setnc', 'seta', 'setna', 'test', 'shl', 'shr',
               'sar', 'shld', 'shrd', 'rcl', 'div', 'call', 'dec', 'jns', 'jc', 'jnc', 'ja', 'jna'}
    while True:
        size, = struct.unpack_from('<I', data, offset)
        offset += 4
        if not size:
            break
        expected, = struct.unpack_from('<Q', data, offset)
        offset += 24 if functions else 8
        code = data[offset:offset+size]
        if len(code) != size:
            raise ValueError('Truncated generated case')
        if functions:
            starts = sorted(ranges.get(count, []))
            if not starts or starts[0] != 0 or len(starts) != len(set(starts)):
                raise ValueError('Invalid exported function boundaries')
            spans = list(zip(starts, starts[1:]+[len(code)]))
        else:
            spans = [(0, len(code))]
        for start, limit in spans:
            audited_code = code[start:limit]
            binary = OUT/'case.bin'
            binary.write_bytes(audited_code)
            disassembly = subprocess.check_output(['ndisasm', '-b32', str(binary)], text=True)
            audited_lines = []
            code_end = None
            for line in disassembly.splitlines():
                parts = line.split()
                mnemonic = parts[2]
                if mnemonic not in allowed:
                    raise ValueError(f'Unexpected instruction: {line}')
                audited_lines.append(line)
                if functions and mnemonic == 'ret':
                    code_end = int(parts[0],16)+len(parts[1])//2
                    break
            if functions:
                if code_end is None or len(audited_code)-code_end > 7 or any(audited_code[code_end:]):
                    raise ValueError('Unexpected function epilogue/padding')
                disassembly = '\n'.join(audited_lines)+'\n'
            listing.append(f'; Case {count}, offset {start}: expected {expected:016X}\n'+disassembly)
        offset += size
        count += 1
    if offset != len(data) or count != (111 if functions else 9):
        raise ValueError('Unexpected test corpus')
    (OUT/'expressions.asm.txt').write_text('\n'.join(listing))
    # NASM -D string macro keeps the fixture independent of a fixed export path.
    disk = OUT/'runner.img'
    run('nasm', *(['-DFUNCTIONS=1'] if functions else []),
        f'-DEXPECTED_FAULTS={4 if functions else 0}', '-f', 'bin', f'-DCASES_FILE="{exports / "expressions.bin"}"',
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
    if result.returncode != 33 or log.read_text() != f'PASS i386 {kind}\n':
        raise RuntimeError(f'Protected-mode runner failed: {log.read_text()}')
    (OUT/'result.json').write_text(json.dumps({'cases': count, 'cpu': '486',
        'ram_mib': 8, 'fault_cases': 4 if functions else 0, 'result': 'pass', 'scope': f'integer {kind} backend'}, indent=2)+'\n')
    print(f'PASS: {count} i386 {kind} cases generated by HolyC; instruction audit.')


if __name__ == '__main__':
    main()
