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
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--functions', action='store_true',
                        help='Test normal function compilation using test-rebuild.py output')
    modes.add_argument('--data', action='store_true', help='Test global/static storage and data imports')
    modes.add_argument('--vga', action='store_true', help='Test native planar VGA presentation and displayed pixels')
    modes.add_argument('--heap', action='store_true', help='Test native arena allocation, coalescing, exhaustion and corruption')
    modes.add_argument('--memory', action='store_true', help='Test BIOS memory handoff and reserved-range selection')
    modes.add_argument('--a20', action='store_true', help='Test A20 gate methods and extended-memory allocation')
    modes.add_argument('--irq', action='store_true', help='Test native PIC/PIT/RTC/keyboard interrupts, input queue, exceptions and frame restoration')
    modes.add_argument('--tasks', action='store_true', help='Test cooperative native task contexts and separate stacks')
    modes.add_argument('--input', action='store_true', help='Test blocking keyboard input and IRQ-driven task wakeups')
    modes.add_argument('--messages', action='store_true', help='Test native message delivery from keyboard broker to consumer')
    args = parser.parse_args()
    task_runner = args.tasks or args.input or args.messages
    kind = 'expressions'
    for mode in ('functions', 'data', 'vga', 'heap', 'memory', 'a20', 'irq', 'tasks', 'input', 'messages'):
        if getattr(args, mode):
            kind = mode
    data_mode = kind in ('data', 'vga', 'heap', 'memory', 'a20', 'irq', 'tasks', 'input', 'messages')
    functions = kind != 'expressions'
    if functions:
        OUT = ROOT/f'build/i386-{kind}-test'
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
    build += ['--overlay', f'tests/guest/i386-{kind}' if functions else 'tests/guest/i386',
              '--output', str(iso)]
    run(*build)
    run(sys.executable, 'tools/guest-run.py', str(iso), '--out', str(exports),
        '--timeout', '90')
    ranges = {}
    linked = set()
    data_ranges = {}
    if functions:
        for line in (exports/'debug.log').read_text().splitlines():
            if line.startswith('LINKED '):
                linked.add(int(line.split()[1]))
            if line.startswith('DATA '):
                _, case, start, size = line.split()
                data_ranges.setdefault(int(case), []).append((int(start, 16), int(size, 16)))
            if line.startswith('RANGE '):
                _, case, start = line.split()
                ranges.setdefault(int(case), []).append(int(start, 16))
    data = (exports/'expressions.bin').read_bytes()
    offset = count = 0
    listing = []
    # Validate only executable ranges: never disassemble record headers as code.
    allowed = {'push', 'pop', 'pushf', 'popf', 'mov', 'add', 'adc', 'sub', 'sbb', 'and', 'or',
               'xor', 'mul', 'imul', 'neg', 'not', 'ret', 'movsx', 'movzx', 'cdq', 'jmp',
               'cmp', 'jz', 'jnz', 'setz', 'setnz', 'setl', 'setnl', 'setg',
               'setng', 'setc', 'setnc', 'seta', 'setna', 'test', 'shl', 'shr',
               'in', 'out', 'sar', 'shld', 'shrd', 'rcl', 'div', 'call', 'dec', 'jns', 'jc', 'jnc', 'ja', 'jna'}
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
            first = 8 if count in linked else 0
            if not starts or (not data_mode and starts[0] != first) or starts[0]<first or starts[-1]>=len(code) or len(starts) != len(set(starts)):
                raise ValueError('Invalid exported function boundaries')
            if count in linked:
                if len(code)<8 or code[0]!=0xE9 or any(code[5:8]):
                    raise ValueError('Invalid linked entry trampoline')
                entry = 5+struct.unpack_from('<i',code,1)[0]
                if entry not in starts:
                    raise ValueError('Entry does not name an exported function')
                listing.append(f'; Case {count}: entry trampoline to {entry:X}')
            regions = sorted(data_ranges.get(count, []))
            covered = bytearray(len(code))
            if count in linked:
                covered[:8] = b'P'*8
            for begin, length in regions:
                if begin<first or length<=0 or begin+length>len(code) or any(covered[begin:begin+length]):
                    raise ValueError('Invalid data boundaries')
                covered[begin:begin+length] = b'D'*length
            boundaries = sorted(set(starts+[begin for begin, _ in regions]+[len(code)]))
            spans = [(start, next(end for end in boundaries if end>start)) for start in starts]
            for start, end in spans:
                if any(covered[start:end]):
                    raise ValueError('Function overlaps data')
                covered[start:end] = b'C'*(end-start)
            gap = 0
            for i, marker in enumerate(covered):
                if marker:
                    gap = 0
                else:
                    gap += 1
                    if code[i] or gap>7:
                        raise ValueError('Unclassified bytes in module image')
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
    if offset != len(data) or count != {'data': 16, 'functions': 155, 'expressions': 9}.get(kind, 1):
        raise ValueError('Unexpected test corpus')
    (OUT/'expressions.asm.txt').write_text('\n'.join(listing))
    # NASM -D string macro keeps the fixture independent of a fixed export path.
    disk = OUT/'runner.img'
    run('nasm', *(['-DBOOT_SECTORS=256'] if task_runner or args.irq else []), *(['-DTASK_TEST=1'] if task_runner else []), *(['-DIRQ_TEST=1'] if args.irq else []), *(['-DVGA_TEST=1'] if args.vga else []), *(['-DFUNCTIONS=1'] if functions else []),
        f'-DEXPECTED_FAULTS={4 if functions and not data_mode else 0}', '-f', 'bin', f'-DCASES_FILE="{exports / "expressions.bin"}"',
        'tests/i386/runner.asm', '-o', str(disk))
    if args.irq or task_runner:
        raw = disk.read_bytes()
        trailer_size = 60 if task_runner else 28
        if raw[-trailer_size:-trailer_size+4] != (b'I32T' if task_runner else b'I32Q'):
            raise ValueError('Missing IRQ assembly boundaries')
        ranges = struct.unpack('<14I' if task_runner else '<6I', raw[-trailer_size+4:])
        irq_allowed = {'push','pop','pusha','popa','pushf','popf','mov','add','xor',
                       'shr','cmp','test','jmp','jz','jnz','jc','jnc','ja','call','ret',
                       'cld','std','cli','sti','hlt','int','int3','div','iret','lidt','lgdt','sgdt','sub','loop','lodsd'}
        assembly = []
        for start, length in zip(ranges[::2], ranges[1::2]):
            if start<512 or length<=0 or start+length>len(raw)-trailer_size:
                raise ValueError('Invalid IRQ assembly boundaries')
            (OUT/'irq-body.bin').write_bytes(raw[start:start+length])
            listing = subprocess.check_output(['ndisasm','-b32',str(OUT/'irq-body.bin')], text=True)
            for line in listing.splitlines():
                parts = line.split()
                if len(parts)==1 and parts[0].startswith('-'):
                    continue  # ndisasm continuation of a long instruction's bytes
                if len(parts)<3 or (parts[2] not in irq_allowed and parts[2:]!=['rep','stosd']):
                    raise ValueError(f'Unexpected IRQ instruction: {line}')
            assembly.append(listing)
        (OUT/'irq-assembly.txt').write_text('\n'.join(assembly))
    if disk.stat().st_size > (257 if task_runner or args.irq else 129)*512:
        raise ValueError('Runner exceeds boot-loader transfer size')
    with disk.open('ab') as stream:
        stream.truncate(16*1024*1024)
    if args.vga:
        run(sys.executable, 'tools/guest-run.py', str(disk), '--i386-disk',
            '--out', str(OUT/'display'), '--timeout', '90')
        from PIL import Image
        screen = Image.open(OUT/'display/screen.ppm').convert('RGB')
        palette = [(0,0,0),(0,0,42),(0,42,0),(0,42,42),
                   (42,0,0),(42,0,42),(42,21,0),(42,42,42),
                   (21,21,21),(21,21,63),(21,63,21),(21,63,63),
                   (63,21,21),(63,21,63),(63,63,21),(63,63,63)]
        # QEMU v10.2.1 hw/display/vga_int.h c6_to_8 repeats the low DAC bit.
        # https://github.com/qemu/qemu/blob/v10.2.1/hw/display/vga_int.h#L150-L156
        palette = [tuple((v<<2)|((v&1)*3) for v in color) for color in palette]
        if screen.size != (640,480):
            raise ValueError(f'Unexpected VGA dimensions: {screen.size}')
        for y in range(480):
            for x in range(640):
                expected = palette[((x//40+y//30)&15)^(x&7)]
                if screen.getpixel((x,y)) != expected:
                    raise ValueError(f'VGA pixel mismatch at {x},{y}: {screen.getpixel((x,y))} != {expected}')
        screen.save(OUT/'display/screen.png')
        (OUT/'result.json').write_text(json.dumps({'result':'pass', 'cpu':'486',
            'ram_mib':8, 'pixels':640*480, 'scope':'native VGA palette and planar upload'}, indent=2)+'\n')
        print('PASS: native VGA upload, all 307200 displayed pixels match.')
        return
    log = OUT/'runner.log'
    log.write_text('')
    cmd = ['qemu-system-i386', '-machine', 'pc', '-accel', 'tcg', '-cpu', '486',
           '-m', '8', '-nic', 'none', '-drive', f'file={disk},format=raw,if=ide',
           '-display', 'none', '-debugcon', f'file:{log}',
           '-device', 'isa-debug-exit,iobase=0xf4,iosize=4', '-no-reboot']
    if args.input or args.messages:
        run(sys.executable, 'tools/i386-input-run.py', str(disk), '--out', str(OUT))
    else:
        result = subprocess.run(cmd, timeout=20)
    runner_kind = 'functions' if functions else 'expressions'
    if not (args.input or args.messages) and (result.returncode != 33 or log.read_text() != f'PASS i386 {runner_kind}\n'):
        raise RuntimeError(f'Protected-mode runner failed: {log.read_text()}')
    if args.memory:
        # Reuse the audited code, changing only its expected firmware-status argument.
        fault_data = bytearray(data)
        struct.pack_into('<Q', fault_data, 12, 1)
        fault_cases = OUT/'cases-no-extended.bin'
        fault_cases.write_bytes(fault_data)
        fault_disk = OUT/'runner-no-extended.img'
        run('nasm', '-DFUNCTIONS=1', '-DEXPECTED_FAULTS=0', '-DBOOT_EXTENDED_FAIL=1',
            '-f', 'bin', f'-DCASES_FILE="{fault_cases}"', 'tests/i386/runner.asm',
            '-o', str(fault_disk))
        if fault_disk.stat().st_size > 129*512:
            raise ValueError('Memory runner exceeds boot-loader transfer size')
        with fault_disk.open('ab') as stream:
            stream.truncate(16*1024*1024)
        fault_log = OUT/'runner-no-extended.log'
        fault_log.write_text('')
        fault_cmd = [arg.replace(str(disk),str(fault_disk)).replace(str(log),str(fault_log)) for arg in cmd]
        fault_result = subprocess.run(fault_cmd, timeout=20)
        if fault_result.returncode != 33 or fault_log.read_text() != 'PASS i386 functions\n':
            raise RuntimeError(f'Legacy-memory query failure test failed: {fault_log.read_text()}')
    (OUT/'result.json').write_text(json.dumps({'cases': count, 'cpu': '486',
        'boot_variants': 2 if args.memory else 1,
        'ram_mib': 8, 'fault_cases': 4 if functions and not data_mode else 0, 'result': 'pass', 'recovered_exceptions': 3 if args.irq else 0, 'scope': 'keyboard broker and task message delivery' if args.messages else 'blocking keyboard input and IRQ-driven task wakeups' if args.input else 'cooperative task contexts' if args.tasks else 'PIC/PIT/RTC/keyboard interrupts, input queue, exceptions and frame restoration' if args.irq else 'A20 methods and extended-memory allocation' if args.a20 else 'BIOS memory handoff and arena selection' if args.memory else 'native arena heap' if args.heap else f'integer {kind} backend'}, indent=2)+'\n')
    print(f'PASS: {count} i386 {kind} cases generated by HolyC; instruction audit.')


if __name__ == '__main__':
    main()
