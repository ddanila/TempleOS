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


def disassemble_i386(code):
    """Keep auditing after ndisasm 3.01's failure to decode FF E0/E2 (JMP EAX/EDX)."""
    result = []
    offset = 0
    while offset < len(code):
        listing = subprocess.check_output(
            ['ndisasm', '-b32', '-o', str(offset), '-'], input=code[offset:]).decode()
        for line in listing.splitlines():
            parts = line.split()
            address = int(parts[0], 16)
            if parts[1:3] == ['FF', 'db'] and code[address:address+2] in (b'\xff\xe0', b'\xff\xe2'):
                register = 'eax' if code[address+1] == 0xe0 else 'edx'
                result.append(f'{address:08X}  FF{code[address+1]:02X}              jmp {register}')
                offset = address+2
                break
            result.append(line)
        else:
            break
    return '\n'.join(result)+'\n'


def native_assembly_args(exports, out, module, prefix, names, cleanup, macro, imports=None):
    """Embed HolyC assembly, binding only explicitly allowed REL32 call imports."""
    imports = imports or {}
    expected_count = len(names)+len(imports)
    context = (exports/f'{module}.t32m').read_bytes()
    magic, version, cpu, pointer, abi, total, code_size, count, records, strings = struct.unpack_from('<IHBB6I', context)
    if (magic, version, cpu, pointer, abi, total, count, records, strings) != (
            0x4D323354, 2, 3, 4, 1, len(context), expected_count, 32+code_size, 32+code_size+16*expected_count):
        raise ValueError(f'Unexpected {module} module layout')
    remaining = set(names) | set(imports)
    entries = []
    patches = []
    for index in range(count):
        kind, address, name_offset, name_length = struct.unpack_from('<4I', context, records+16*index)
        if kind not in (1, 2) or address >= code_size or name_offset < strings or name_offset+name_length >= total:
            raise ValueError(f'{module} must contain bounded code exports/call imports')
        name = context[name_offset:name_offset+name_length].decode('ascii')
        if name not in remaining or context[name_offset+name_length] != 0:
            raise ValueError(f'Unexpected {module} export')
        remaining.remove(name)
        if kind == 1 and name in names:
            entries.append((address, name))
        elif kind == 2 and name in imports and 0 < address <= code_size-4:
            if context[32+address-1] != 0xE8:
                raise ValueError(f'{module} import is not a relative CALL')
            patches.append((address, imports[name]))
        else:
            raise ValueError(f'Unexpected {module} symbol kind')
    code = context[32:32+code_size]
    returns = [line.split() for line in disassemble_i386(code).splitlines()
               if len(line.split()) >= 3 and line.split()[2] == ('iret' if cleanup is None else 'ret')]
    if not returns:
        raise ValueError(f'Missing {module} return')
    end = int(returns[-1][0], 16)+len(returns[-1][1])//2
    tail = b'\xcf' if cleanup is None else b'\xc2'+struct.pack('<H', cleanup)
    if code[end-len(tail):end] != tail or len(code)-end > 7 or any(code[end:]):
        raise ValueError(f'Unexpected {module} tail/padding')
    entries.sort()
    if entries[0][0] != 0:
        raise ValueError(f'Unaccounted code before first {module} export')
    definitions = []
    for index, (address, name) in enumerate(entries):
        limit = entries[index+1][0] if index+1 < len(entries) else end
        if address >= limit:
            raise ValueError(f'Empty or overlapping {module} entry')
        definitions.extend((f'{name} equ {prefix}_begin+{address}',
                            f'{name}_end equ {prefix}_begin+{limit}'))
    body = out/f'{module}.bin'
    body.write_bytes(code[:end])
    include = out/f'{module}.inc'
    payload = []
    position = 0
    for address, symbol in sorted(patches):
        if address < position or address+4 > end:
            raise ValueError(f'Overlapping/out-of-range {module} call patch')
        payload.append(f'incbin "{body}",{position},{address-position}')
        payload.append(f'dd {symbol}-($+4)')
        position = address+4
    payload.append(f'incbin "{body}",{position},{end-position}')
    include.write_text('\n'.join(definitions)+f'\n{prefix}_begin:\n'+
                       '\n'.join(payload)+f'\n{prefix}_end:\n')
    return [f'-D{macro}="{include}"']


def main():
    global OUT
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--functions', action='store_true',
                        help='Test normal function compilation using test-rebuild.py output')
    modes.add_argument('--inline-asm', action='store_true', help='Test native HolyC inline assembly and relative label fixups')
    modes.add_argument('--data', action='store_true', help='Test global/static storage and data imports')
    modes.add_argument('--vga', action='store_true', help='Test native planar VGA presentation and displayed pixels')
    modes.add_argument('--except-tasks', action='store_true', help='Test public exceptions across native task switches')
    modes.add_argument('--except-runtime', action='store_true', help='Test FS-bound native SysTry, SysUntry and public throw')
    modes.add_argument('--except-context', action='store_true', help='Test native exception capture, catch invocation and resume primitives')
    modes.add_argument('--except-records', action='store_true', help='Test native task-owned exception record lifetime')
    modes.add_argument('--lex-string', action='store_true', help='Test shared quoted-string decoding and native reader failures')
    modes.add_argument('--lex-state', action='store_true', help='Test lexer snapshot state and native ownership against x64')
    modes.add_argument('--symbols', action='store_true', help='Test shared compiler symbol layouts and HashVal against the legacy x64 kernel')
    modes.add_argument('--hash', action='store_true', help='Test native hash primitives against x64 hashing and table semantics')
    modes.add_argument('--heap', action='store_true', help='Test native arena allocation, coalescing, exhaustion and corruption')
    modes.add_argument('--memory', action='store_true', help='Test BIOS memory handoff and reserved-range selection')
    modes.add_argument('--a20', action='store_true', help='Test A20 gate methods and extended-memory allocation')
    modes.add_argument('--irq', action='store_true', help='Test native PIC/PIT/RTC/keyboard interrupts, input queue, exceptions and frame restoration')
    modes.add_argument('--tasks', action='store_true', help='Test cooperative native task contexts and separate stacks')
    modes.add_argument('--input', action='store_true', help='Test blocking keyboard input and IRQ-driven task wakeups')
    modes.add_argument('--messages', action='store_true', help='Test native message delivery from keyboard broker to consumer')
    modes.add_argument('--ata', action='store_true', help='Test native ATA identify, single-sector PIO and cache flush')
    modes.add_argument('--redsea', action='store_true', help='Test native RedSea mount, lookup and raw file reads')
    modes.add_argument('--redsea-write', action='store_true', help='Test native fixed-extent RedSea file updates')
    modes.add_argument('--redsea-alloc', action='store_true', help='Test native RedSea bitmap allocation and release')
    modes.add_argument('--redsea-create', action='store_true', help='Test native RedSea file creation and publication ordering')
    modes.add_argument('--redsea-delete', action='store_true', help='Test native RedSea deletion, reclamation and reuse')
    modes.add_argument('--redsea-replace', action='store_true', help='Test native RedSea replacement without early reclamation')
    modes.add_argument('--redsea-load', action='store_true', help='Test loading native modules from RedSea files')
    modes.add_argument('--redsea-load-set', action='store_true', help='Test linked module sets loaded from RedSea')
    modes.add_argument('--redsea-bind', action='store_true', help='Test modules bound to resident functions and data')
    modes.add_argument('--soft-f64', action='store_true', help='Test integer-only binary64 addition, subtraction, multiplication and division')
    modes.add_argument('--soft-f64-convert', action='store_true', help='Test I64/U64 to binary64 conversion and rounding')
    modes.add_argument('--soft-f64-compare', action='store_true', help='Test binary64 ordering, NaNs and signed zeros')
    modes.add_argument('--soft-f64-to-int', action='store_true', help='Test binary64 to I64/Bool conversion against x64 HolyC')
    modes.add_argument('--soft-f64-log', action='store_true', help='Test software Ln, Log10 and Log2 against high-precision and x64 oracles')
    modes.add_argument('--soft-f64-unary', action='store_true', help='Test software F64 Abs/Sqr/Sqrt and integral rounding against x64 and a host oracle')
    modes.add_argument('--integer-math', action='store_true', help='Test integer math intrinsics against x64 and Python')
    modes.add_argument('--float', action='store_true', help='Test compiled native HolyC F64 expressions and calls')
    args = parser.parse_args()
    except_runner = args.except_context or args.except_runtime
    task_runner = args.tasks or args.input or args.messages or args.except_tasks
    large_runner = args.lex_string or args.lex_state or args.symbols or args.hash or args.functions or args.soft_f64_log or args.soft_f64_unary or args.float or args.integer_math or args.soft_f64 or task_runner or args.irq or args.redsea_create or args.redsea_delete or args.redsea_replace or args.redsea_load or args.redsea_load_set or args.redsea_bind
    #Task and symbol integration corpora use a 160 KiB transfer; their first arena is 0x40000.
    #A 160 KiB transfer from 0x10000 ends at 0x38000, below that arena.
    boot_sectors = 320 if args.tasks or args.except_tasks or args.symbols else 256 if large_runner else 128
    kind = 'expressions'
    for mode in ('functions', 'inline-asm', 'data', 'vga', 'heap', 'hash', 'symbols', 'lex-state', 'lex-string', 'except-records', 'except-context', 'except-runtime', 'except-tasks', 'memory', 'a20', 'irq', 'tasks', 'input', 'messages', 'ata', 'redsea', 'redsea-write', 'redsea-alloc', 'redsea-create', 'redsea-delete', 'redsea-replace', 'redsea-load', 'redsea-load-set', 'redsea-bind', 'soft-f64', 'soft-f64-convert', 'soft-f64-compare', 'soft-f64-to-int', 'soft-f64-log', 'soft-f64-unary', 'integer-math', 'float'):
        if getattr(args, mode.replace('-', '_')):
            kind = mode
    data_mode = kind in ('inline-asm', 'data', 'vga', 'heap', 'hash', 'symbols', 'lex-state', 'lex-string', 'except-records', 'except-context', 'except-runtime', 'except-tasks', 'memory', 'a20', 'irq', 'tasks', 'input', 'messages', 'ata', 'redsea', 'redsea-write', 'redsea-alloc', 'redsea-create', 'redsea-delete', 'redsea-replace', 'redsea-load', 'redsea-load-set', 'redsea-bind', 'soft-f64', 'soft-f64-convert', 'soft-f64-compare', 'soft-f64-to-int', 'soft-f64-log', 'soft-f64-unary', 'integer-math', 'float')
    if args.soft_f64_unary:
        run(sys.executable, 'tools/gen-i386-pow10.py', '--check')
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
    if except_runner or args.except_tasks:
        #Discard the old NASM artifact; the guest now builds SysTry from HolyC.
        (OUT/'overlay/SysTry.T32').unlink(missing_ok=True)
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
    interrupt_ranges = {}
    if functions:
        for line in (exports/'debug.log').read_text().splitlines():
            if line.startswith('LINKED '):
                linked.add(int(line.split()[1]))
            if line.startswith('DATA '):
                _, case, start, size = line.split()
                data_ranges.setdefault(int(case), []).append((int(start, 16), int(size, 16)))
            if line.startswith('INTERRUPT '):
                _, case, start, size = line.split()
                key = (int(case), int(start, 16))
                if not (args.irq or args.except_tasks) or key in interrupt_ranges:
                    raise ValueError('Unexpected/duplicate interrupt code range')
                interrupt_ranges[key] = int(size, 16)
            if line.startswith('RANGE '):
                _, case, start = line.split()
                ranges.setdefault(int(case), []).append(int(start, 16))
    if args.symbols:
        baseline=json.loads((ROOT/'tests/i386/symbol-values.json').read_text())
        if hashlib.sha256((ROOT/'tests/guest/i386-symbols/Values.HC').read_bytes()).hexdigest()!=baseline['values_source_sha256']:
            raise ValueError('Symbol-value fixture differs from its legacy capture')
        expected=b''.join(struct.pack('<Q',int(value,16)) for value in baseline['values'])
        if (exports/'symbol-values.bin').read_bytes()!=expected:
            raise ValueError('Shared HashVal differs from pre-refactor x64 behavior')
    data = (exports/'expressions.bin').read_bytes()
    if args.soft_f64_log or args.soft_f64_unary or args.integer_math or args.soft_f64 or args.soft_f64_convert or args.soft_f64_compare or args.soft_f64_to_int:
        from i386_integer_oracle import make_integer_math_oracle
        from i386_log_oracle import make_log_oracle
        from i386_f64_oracle import make_oracle, make_conversion_oracle, make_comparison_oracle, make_to_int_oracle, make_unary_oracle
        records = [line.split() for line in (exports/'debug.log').read_text().splitlines()
                   if line.startswith('ORACLE ')]
        if len(records) != 1:
            raise ValueError('Missing/duplicate numeric oracle export')
        begin, length = (int(value, 16) for value in records[0][1:])
        oracle = (make_log_oracle() if args.soft_f64_log else make_unary_oracle(1024) if args.soft_f64_unary else make_integer_math_oracle() if args.integer_math else make_to_int_oracle(1024) if args.soft_f64_to_int else
                  make_comparison_oracle(1024) if args.soft_f64_compare else
                  make_conversion_oracle(1024) if args.soft_f64_convert else make_oracle(2048))
        if args.soft_f64_log:
            x64 = (exports/'x64-log.bin').read_bytes()
            if len(x64) != len(oracle):
                raise ValueError('Unexpected x64 logarithm export size')
            for actual, expected in zip(struct.iter_unpack('<4Q', x64), struct.iter_unpack('<4Q', oracle)):
                if actual[0] != expected[0]:
                    raise ValueError('Logarithm oracle input mismatch')
                for got, want, tolerance in zip(actual[1:], expected[1:], (1, 2, 2)):
                    if (want & 0x7FFFFFFFFFFFFFFF) >= 0x7FF0000000000000 or not want:
                        good = got == want
                    else:
                        good = not ((got ^ want) >> 63) and abs(got-want) <= tolerance
                    if not good:
                        raise ValueError(f'x64 logarithm differs from oracle at {actual[0]:016X}')
        if args.soft_f64_unary:
            #Observed x87 extended-precision square-root double rounding.
            #Keep the correctly rounded oracle for native execution.
            x64_roots = {0x5FEFFFFFFFFFFFFF: 0x4FF0000000000000,
                         0x7FEFFFFFFFFFFFFF: 0x5FF0000000000000,
                         0x432FFFFFFFFFFFFF: 0x4190000000000000,
                         0x3FEFFFFFFFFFFFFF: 0x3FF0000000000000}
            x64_squares = {0x3FF7FFFFFFFFFFFF: 0x4001FFFFFFFFFFFE,
                           0x4004000000000001: 0x4019000000000002}
            x64_oracle = b''.join(struct.pack('<8Q', value, absolute,
                x64_squares.get(value & 0x7FFFFFFFFFFFFFFF, square),
                x64_roots.get(value, root), *integral) for value, absolute, square, root, *integral
                in struct.iter_unpack('<8Q', oracle[:65536]))
            if (exports/'x64-unary.bin').read_bytes() != x64_oracle:
                raise ValueError('x64 unary results differ from documented precision observations')
            powers = (exports/'x64-pow10.bin').read_bytes()
            powers_hash = hashlib.sha256(powers).hexdigest()
            if powers_hash != '2e249f8317610dbc84966a4c91a4b913fff7878ca21e66f3ad13cbbc68962543':
                raise ValueError('x64 Pow10I64 results differ from documented observations')
            differences = [dict(exponent=i-308, x64=f'{actual:016X}',
                                native=f'{exact:016X}', ulps=abs(actual-exact))
                for i, ((actual,), (exact,)) in enumerate(zip(
                    struct.iter_unpack('<Q', powers), struct.iter_unpack('<Q', oracle[65536:])))
                if actual != exact]
            (OUT/'pow10-compatibility.json').write_text(json.dumps(dict(
                x64_sha256=powers_hash, vectors=617, differences=differences,
                max_ulps=max((item['ulps'] for item in differences), default=0)), indent=2)+'\n')
        if args.integer_math and (exports/'x64-integer-math.bin').read_bytes() != oracle:
            raise ValueError('x64 integer math differs from the Python oracle')
        if args.soft_f64_convert:
            signed_inputs = (0, 1, 0xFFFFFFFFFFFFFFFF, 0x8000000000000000,
                             0x7FFFFFFFFFFFFFFF, 0x0020000000000001,
                             0xFFE0000000000001, 0x8000000000000001)
            signed_oracle = b''.join(struct.pack('<Qd', value,
                float(value-(1 << 64) if value >> 63 else value)) for value in signed_inputs)
            if (exports/'x64-from-int.bin').read_bytes() != signed_oracle:
                raise ValueError('x64 ToF64 does not match signed I64 conversion')
        if args.soft_f64_to_int:
            expected_bools = bytes(truth for bits, value in struct.iter_unpack('<QQ', oracle)
                                   for truth in (value != 0, bits != 0))
            if (exports/'x64-to-bool.bin').read_bytes() != expected_bools:
                raise ValueError('x64 ToBool differs from the numeric-conversion/raw-bit contract')
        if args.soft_f64_to_int and (exports/'x64-to-int.bin').read_bytes() != oracle:
            raise ValueError('x64 HolyC conversion differs from truncation/indefinite oracle')
        if length != len(oracle) or begin < 28 or begin+length > len(data)-4:
            raise ValueError('Invalid numeric oracle bounds')
        if not any(begin == 28+start and length == size for start, size in data_ranges.get(0, [])):
            raise ValueError('numeric oracle is not an exported data region')
        data = data[:begin]+oracle+data[begin+length:]
        (exports/'expressions.bin').write_bytes(data)
    offset = count = 0
    listing = []
    # Validate only executable ranges: never disassemble record headers as code.
    allowed = {'lgdt', 'sgdt', 'sti', 'cli', 'hlt', 'cld', 'pusha', 'popa', 'iret', 'lidt', 'sidt', 'push', 'pop', 'pushf', 'popf', 'mov', 'lea', 'add', 'adc', 'sub', 'sbb', 'and', 'or',
               'bt', 'bts', 'btr', 'btc', 'bsf', 'bsr', 'xor', 'mul', 'imul', 'neg', 'not', 'ret', 'movsx', 'movzx', 'cdq', 'jmp',
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
            disassembly = disassemble_i386(audited_code)
            lines = disassembly.splitlines()
            if functions:
                interrupt_size = interrupt_ranges.pop((count, start), None)
                if interrupt_size is not None and interrupt_size != limit-start:
                    raise ValueError('Interrupt code range does not match executable span')
                returns = [index for index, line in enumerate(lines)
                           if len(line.split()) >= 3 and line.split()[2] ==
                           ('iret' if interrupt_size is not None else 'ret')]
                if not returns:
                    raise ValueError('Missing function return')
                last_return = returns[-1]
                parts = lines[last_return].split()
                code_end = int(parts[0], 16)+len(parts[1])//2
                if len(audited_code)-code_end > 7 or any(audited_code[code_end:]):
                    raise ValueError('Unexpected function epilogue/padding')
                #Switch start blocks can contain internal RETs; audit through the final one.
                lines = lines[:last_return+1]
            audited_lines = []
            for line in lines:
                parts = line.split()
                mnemonic = parts[2]
                locked_bit = parts[2:] in (["lock", op, "[eax],esi"] for op in ("bts", "btr", "btc"))
                if mnemonic not in allowed and not locked_bit:
                    raise ValueError(f'Unexpected instruction: {line}')
                audited_lines.append(line)
            if functions:
                disassembly = '\n'.join(audited_lines)+'\n'
            listing.append(f'; Case {count}, offset {start}: expected {expected:016X}\n'+disassembly)
        offset += size
        count += 1
    if offset != len(data) or count != {'data': 16, 'functions': 233, 'expressions': 9, 'redsea-load': 2, 'redsea-load-set': 2, 'redsea-bind': 2}.get(kind, 1):
        raise ValueError('Unexpected test corpus')
    if interrupt_ranges:
        raise ValueError('Unmatched interrupt code range')
    (OUT/'expressions.asm.txt').write_text('\n'.join(listing))
    if args.lex_state:
        #Single-CPU value tests cannot prove that the locked prefix was emitted.
        instructions = [line.split()[2:] for block in listing for line in block.splitlines()
                        if line and not line.startswith(';')]
        for operation in ('bts', 'btr', 'btc'):
            if ['lock', operation, '[eax],esi'] not in instructions:
                raise ValueError(f'Missing locked bit intrinsic: {operation}')
        for operation in ('bt', 'bts', 'btr', 'btc', 'bsf', 'bsr'):
            if not any(parts and parts[0] == operation for parts in instructions):
                raise ValueError(f'Missing bit intrinsic: {operation}')
    # NASM -D string macro keeps the fixture independent of a fixed export path.
    context_args = []
    if except_runner or args.except_tasks:
        context_args += native_assembly_args(exports, OUT, 'ExceptContext',
            'i386_except_context', ('i386_except_save', 'i386_except_invoke',
            'i386_except_resume', 'i386_except_register'), 40, 'EXCEPT_CONTEXT_FILE')
    if task_runner:
        context_args += native_assembly_args(exports, OUT, 'TaskContext',
            'i386_task_context', ('i386_context_switch', 'i386_idle',
            'i386_segments_reload'), 16, 'TASK_CONTEXT_FILE')
    if args.irq or task_runner:
        for module, stem, vectors, dispatch in (
                ('IrqEntry', 'irq', 16, 'I386IrqDispatch'),
                ('ExceptionEntry', 'exception', 17, 'I386ExceptionDispatch')):
            context_args += native_assembly_args(exports, OUT, module,
                f'i386_{stem}_module', tuple(f'i386_{stem}_{i}' for i in range(vectors)),
                None, f'{stem.upper()}_ENTRY_FILE', {dispatch: f'i386_{stem}_callback'})
    disk = OUT/'runner.img'
    run('nasm', *(['-DEXCEPT_TASK_TEST=1'] if args.except_tasks else []), *(['-DEXCEPT_CONTEXT_TEST=1'] if except_runner else []), *(['-DSOFT_F64_TEST=1'] if args.soft_f64_log or args.soft_f64_unary or args.soft_f64 or args.soft_f64_convert or args.soft_f64_compare or args.soft_f64_to_int or args.float else []), f'-DBOOT_SECTORS={boot_sectors}', *(['-DTASK_TEST=1'] if task_runner else []), *(['-DIRQ_TEST=1'] if args.irq else []), *(['-DVGA_TEST=1'] if args.vga else []), *(['-DFUNCTIONS=1'] if functions else []),
        *context_args, f'-DEXPECTED_FAULTS={5 if functions and not data_mode else 0}', '-f', 'bin', f'-DCASES_FILE="{exports / "expressions.bin"}"',
        'tests/i386/runner.asm', '-o', str(disk))
    if args.irq or task_runner or except_runner:
        raw = disk.read_bytes()
        trailer_size = 68 if args.except_tasks else 28 if except_runner else 60 if task_runner else 28
        if raw[-trailer_size:-trailer_size+4] != (b'I32E' if except_runner else b'I32T' if task_runner else b'I32Q'):
            raise ValueError('Missing IRQ assembly boundaries')
        ranges = struct.unpack('<16I' if args.except_tasks else '<6I' if except_runner else '<14I' if task_runner else '<6I', raw[-trailer_size+4:])
        irq_allowed = {'push','pop','pusha','popa','pushf','popf','mov','add','xor',
                       'shr','cmp','test','jmp','jz','jnz','jc','jnc','ja','call','ret',
                       'and','lea','cld','std','cli','sti','hlt','int','int3','div','iret','lidt','lgdt','sgdt','sub','loop','lodsd'}
        assembly = []
        for start, length in zip(ranges[::2], ranges[1::2]):
            if start<512 or length<=0 or start+length>len(raw)-trailer_size:
                raise ValueError('Invalid IRQ assembly boundaries')
            (OUT/'irq-body.bin').write_bytes(raw[start:start+length])
            listing = disassemble_i386(raw[start:start+length])
            for line in listing.splitlines():
                parts = line.split()
                if len(parts)==1 and parts[0].startswith('-'):
                    continue  # ndisasm continuation of a long instruction's bytes
                if len(parts)<3 or (parts[2] not in irq_allowed and parts[2:]!=['rep','stosd']):
                    raise ValueError(f'Unexpected IRQ instruction: {line}')
            assembly.append(listing)
        (OUT/'irq-assembly.txt').write_text('\n'.join(assembly))
    if disk.stat().st_size > (boot_sectors+1)*512:
        raise ValueError('Runner exceeds boot-loader transfer size')
    with disk.open('ab') as stream:
        stream.truncate(16*1024*1024)
    if args.ata:
        with disk.open('r+b') as stream:
            # Seed beyond the bootstrap, including geometry-dependent CHS boundaries.
            patterns = [bytes(((i*37)^(i>>1)^seed)&255 for i in range(512))
                        for seed in range(256)]
            stream.seek(512*512)
            for lba in range(512, 32768):
                stream.write(patterns[(lba^(lba>>8))&255])
    if args.redsea or args.redsea_write or args.redsea_alloc or args.redsea_create or args.redsea_delete or args.redsea_replace or args.redsea_load or args.redsea_load_set or args.redsea_bind:
        def rs_entry(name, attr, block, size):
            return struct.pack('<H38sqqQ', attr, name.encode('ascii'), block, size, 0x123456789ABCDEF0)
        def rs_boot(start, sectors=128, root=2050, bitmap=1):
            record = bytearray(512)
            record[3] = 0x88
            struct.pack_into('<5q', record, 8, start, sectors, root, bitmap, 1)
            struct.pack_into('<H', record, 510, 0xAA55)
            return record
        root = bytearray(1024)
        entries = [rs_entry('.', 0x810, 2050, 1024), rs_entry('..', 0x810, 2050, 0),
                   rs_entry('DATA.BIN', 0x900, -1, -1)]  # deleted, skip invalid extent
        entries += [rs_entry(f'Empty{i}', 0x800, 0, 0) for i in range(5)]
        entries += [rs_entry('DATA.BIN', 0x800, 2053, 1300),
                    rs_entry('Tools', 0x810, 2052, 512), rs_entry('Empty', 0x800, 0, 0),
                    rs_entry('Bad', 0x810, 2057, 512)]
        root[:len(entries)*64] = b''.join(entries)
        sub = bytearray(512)
        source = b'I64 Twice(I64 x) { return x*2; }\n'
        sub[:192] = b''.join([rs_entry('.', 0x810, 2052, 512),
                             rs_entry('..', 0x810, 2050, 0),
                             rs_entry('Source.HC', 0x800, 2056, len(source))])
        bad = bytearray(512)
        bad[:128] = rs_entry('.', 0x810, 2057, 512)+rs_entry('Outside', 0x800, 2175, 1024)
        with disk.open('r+b') as stream:
            for block, content in ((2048, rs_boot(2048)), (2049, bytes([255])*512),
                    (2050, root), (2052, sub), (2053, bytes(((i*19)^(i>>4))&255 for i in range(1300))),
                    (2056, source), (2057, bad), (32767, bytes([0x6C])*512)):
                stream.seek(block*512)
                stream.write(content)
            # Invalid signatures, volume sizes, bitmap coverage and root extents.
            for index in range(6):
                boot = rs_boot(3072+index, root=3100)
                if index == 0: boot[3] = 0
                if index == 1: struct.pack_into('<q', boot, 16, -1)
                if index == 2: struct.pack_into('<q', boot, 16, 1 << 62)
                if index == 3: struct.pack_into('<q', boot, 32, 0)
                if index == 4: struct.pack_into('<q', boot, 24, 32768)
                if index == 5: struct.pack_into('<q', boot, 8, 0)
                stream.seek((3072+index)*512)
                stream.write(boot)
            stream.seek(3100*512)
            stream.write(rs_entry('.', 0x810, 3100, 512)+bytes(448))
            stream.seek(3078*512)
            stream.write(rs_boot(3078, root=3100))
        if args.redsea_alloc:
            bitmap = bytearray(1024)
            bitmap[0] = 3  # last bitmap sector and root directory are allocated
            bitmap[-1] = 0xC0  # bits beyond the declared volume must never be used
            root = rs_entry('.', 0x810, 2051, 512)+bytes(448)
            with disk.open('r+b') as stream:
                stream.seek(2048*512)
                stream.write(rs_boot(2048, sectors=8192, root=2051, bitmap=2))
                stream.write(bitmap)
                stream.write(root)
        if args.redsea_create or args.redsea_delete or args.redsea_replace:
            bitmap = bytearray(1024)
            bitmap[0] = 0x8F  # metadata, full directory, and read-only directory at bit 7
            bitmap[-1] = 0xC0
            root = bytearray(1024)
            entries = [rs_entry('.', 0x810, 2051, 1024), rs_entry('..', 0x810, 2051, 0),
                       rs_entry('Gone', 0x900, 0, 0), rs_entry('Full', 0x810, 2053, 512)]
            entries += [rs_entry('ReadOnly', 0x811, 2057, 512)]
            entries += [rs_entry(f'F{i}', 0x800, 0, 0) for i in range(5, 7)]
            root[:448] = b''.join(entries)
            if args.redsea_delete or args.redsea_replace:
                root[5*64:6*64] = rs_entry('F5', 0x801, 0, 0)
            root[512:640] = rs_entry('Ghost', 0x800, 0, 0)+rs_entry('Ghost2', 0x800, 0, 0)
            full = rs_entry('.', 0x810, 2053, 512)+rs_entry('..', 0x810, 2051, 0)
            full += b''.join(rs_entry(f'F{i}', 0x800, 0, 0) for i in range(6))
            with disk.open('r+b') as stream:
                stream.seek(2048*512)
                stream.write(rs_boot(2048, sectors=8192, root=2051, bitmap=2))
                stream.write(bitmap)
                stream.write(root)
                stream.write(full)
                stream.seek(2057*512)
                stream.write(rs_entry('.', 0x811, 2057, 512)+bytes(448))
        if args.redsea_replace:
            original_source = b'I64 Answer() { return 1; }\n'
            with disk.open('r+b') as stream:
                stream.seek(2049*512)
                stream.write(bytes([0x9F]))
                stream.seek(2051*512+2*64)
                stream.write(struct.pack('<H38sqqQ', 0x822, b'Saved.HC', 2054,
                                         len(original_source), 777))
                stream.seek(2054*512)
                stream.write(original_source)
                stream.seek(12288*512)
                stream.write(rs_boot(12288, sectors=128, root=12290))
                stream.write(bytes([255])*512)
                stream.write(rs_entry('.', 0x810, 12290, 512)+
                             rs_entry('Kept', 0x800, 12291, 1)+bytes(384))
                stream.write(b'K'+bytes(511))
        if args.redsea_load:
            payload = (exports/'payload.t32m').read_bytes()
            if len(payload) >= 2048:
                raise ValueError('Module file fixture exceeds reserved sector spacing')
            wrong = bytearray(payload)
            wrong[7] = 8  # reject a non-i386 pointer-width contract
            entries = [rs_entry('.', 0x810, 2050, 512), rs_entry('..', 0x810, 2050, 0),
                       rs_entry('Good.T32M', 0x800, 2060, len(payload)),
                       rs_entry('Wrong.T32M', 0x800, 2064, len(wrong)),
                       rs_entry('Short.T32M', 0x800, 2068, len(payload)-1),
                       rs_entry('Tiny.T32M', 0x800, 2072, 16)]
            with disk.open('r+b') as stream:
                stream.seek(2050*512)
                stream.write(b''.join(entries)+bytes(512-len(entries)*64))
                for block, content in ((2060, payload), (2064, wrong), (2068, payload[:-1]),
                                       (2072, bytes(16))):
                    stream.seek(block*512)
                    stream.write(content)
        if args.redsea_load_set or args.redsea_bind:
            consumer = (exports/'consumer.t32m').read_bytes()
            provider = (exports/'provider.t32m').read_bytes()
            if max(len(consumer), len(provider)) >= 2048:
                raise ValueError('Module set fixture exceeds reserved sector spacing')
            wrong = bytearray(provider)
            wrong[7] = 8
            entries = [rs_entry('.', 0x810, 2050, 512), rs_entry('..', 0x810, 2050, 0),
                       rs_entry('Consumer.T32M', 0x800, 2060, len(consumer)),
                       rs_entry('Provider.T32M', 0x800, 2064, len(provider)),
                       rs_entry('Wrong.T32M', 0x800, 2068, len(wrong)),
                       rs_entry('Short.T32M', 0x800, 2072, len(provider)-1)]
            with disk.open('r+b') as stream:
                stream.seek(2050*512)
                stream.write(b''.join(entries)+bytes(512-len(entries)*64))
                for block, content in ((2060, consumer), (2064, provider), (2068, wrong),
                                       (2072, provider[:-1])):
                    stream.seek(block*512)
                    stream.write(content)
        redsea_before = disk.read_bytes()
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
    if args.ata:
        ata_before = disk.read_bytes()
    log = OUT/'runner.log'
    log.write_text('')
    cmd = ['qemu-system-i386', '-machine', 'pc', '-accel', 'tcg', '-cpu', '486',
           '-m', '8', '-nic', 'none', '-drive', f'file={disk},format=raw,if=ide',
           '-display', 'none', '-debugcon', f'file:{log}',
           '-device', 'isa-debug-exit,iobase=0xf4,iosize=4', '-no-reboot']
    if args.ata or args.redsea_create or args.redsea_delete or args.redsea_replace:
        ata_trace = OUT/'ata-commands.log'
        ata_trace.write_text('')
        cmd += ['-trace', f'enable=ide_bus_exec_cmd,file={ata_trace}']
    if args.input or args.messages:
        run(sys.executable, 'tools/i386-input-run.py', str(disk), '--out', str(OUT))
    else:
        result = subprocess.run(cmd, timeout=20)
    runner_kind = 'functions' if functions else 'expressions'
    if not (args.input or args.messages) and (result.returncode != 33 or log.read_text() != f'PASS i386 {runner_kind}\n'):
        raise RuntimeError(f'Protected-mode runner failed: {log.read_text()}')
    if args.ata:
        # Observe the actual command stream as well as the guest return values.
        commands = [int(line.rsplit('cmd 0x', 1)[1], 16)
                    for line in ata_trace.read_text().splitlines()
                    if 'ide_bus_exec_cmd' in line and 'cmd 0x' in line]
        if commands[-13:] != [0x30, 0xE7, 0x20]*4+[0xE7]:
            raise RuntimeError('ATA trace lacks expected write/flush/read command ordering')
        # Check backing storage after QEMU exits, not just guest readback.
        expected_disk = bytearray(ata_before)
        for lba, generation in ((4096, 3), (32767, 1), (4097, 2)):
            expected_disk[lba*512:(lba+1)*512] = bytes(
                ((i*19)^(i>>2)^(generation*67)^0xA6)&255 for i in range(512))
        if disk.read_bytes() != expected_disk:
            raise RuntimeError('ATA backing image differs from the three expected sector writes')
        (OUT/'write-check.json').write_text(json.dumps({
            'result': 'pass', 'bytes_compared': len(expected_disk),
            'changed_sectors': [4096, 4097, 32767],
            'verified_flush_commands': 5,
            'scope': 'QEMU backing image after process exit; not power-loss durability'
        }, indent=2)+'\n')
    if (args.redsea or args.redsea_alloc or args.redsea_load or args.redsea_load_set or args.redsea_bind) and disk.read_bytes() != redsea_before:
        raise RuntimeError('RedSea backing image differs after read-only access or full allocation reclamation')
    if args.redsea_write:
        expected_disk = bytearray(redsea_before)
        base = 2053*512
        for file_offset, length, seed in ((509, 520, 0x67), (0, 512, 0xA9), (1295, 5, 0x3C)):
            expected_disk[base+file_offset:base+file_offset+length] = bytes(
                ((i*29)^(i>>3)^seed)&255 for i in range(length))
        expected_disk[32767*512:32768*512] = bytes(
            ((i*29)^(i>>3)^0x67)&255 for i in range(512))
        if disk.read_bytes() != expected_disk:
            raise RuntimeError('RedSea update changed unexpected file, padding or metadata bytes')
        (OUT/'write-check.json').write_text(json.dumps({
            'result': 'pass', 'bytes_compared': len(expected_disk),
            'file_updates': [[509, 520], [0, 512], [1295, 5]],
            'fault_test_changed_sector': 32767,
            'scope': 'fixed-extent updates and partial I/O; metadata and all other bytes unchanged'
        }, indent=2)+'\n')
    if args.redsea_create:
        expected_disk = bytearray(redsea_before)
        expected_disk[2049*512] = 0xFF
        created_source = b'I64 Answer() { return 42; }\n'
        for slot, name, block, length, date in (
                (2, 'Created.BIN', 2054, 700, 0xFEDCBA9876543210),
                (7, 'Answer.HC', 2056, len(created_source), 12345),
                (8, 'EmptyNew', 0, 0, 0)):
            location = 2051*512+slot*64
            expected_disk[location:location+64] = struct.pack(
                '<H38sqqQ', 0x800, name.encode('ascii'), block, length, date)
        expected_disk[2051*512+9*64:2051*512+10*64] = bytes(64)
        expected_disk[2054*512:2054*512+700] = bytes(
            ((i*17)^(i>>2)^0x95)&255 for i in range(700))
        expected_disk[2056*512:2056*512+len(created_source)] = created_source
        if disk.read_bytes() != expected_disk:
            raise RuntimeError('RedSea file creation differs from expected data/bitmap/directory bytes')
        commands = [int(line.rsplit('cmd 0x', 1)[1], 16)
                    for line in ata_trace.read_text().splitlines()
                    if 'ide_bus_exec_cmd' in line and 'cmd 0x' in line]
        writes_flushes = [command for command in commands if command in (0x30, 0xE7)]
        expected_order = [0x30,0x30,0x30,0xE7,0x30,0xE7,
                          0x30,0x30,0xE7,0x30,0xE7,0x30,0xE7,0xE7,0x30,0xE7]
        if writes_flushes[-len(expected_order):] != expected_order:
            raise RuntimeError('RedSea publication lacks expected data/terminator/directory flush ordering')
    if args.redsea_delete:
        expected_disk = bytearray(redsea_before)
        expected_disk[2049*512] = 0x9F
        created_source = b'I64 Answer() { return 42; }\n'
        for slot, name, attr, block, length, date in (
                (2, 'Reused.HC', 0x800, 2054, len(created_source), 12345),
                (7, 'EmptyTemp', 0x900, 0, 0, 0)):
            location = 2051*512+slot*64
            expected_disk[location:location+64] = struct.pack(
                '<H38sqqQ', attr, name.encode('ascii'), block, length, date)
        expected_disk[2051*512+8*64:2051*512+9*64] = bytes(64)
        expected_disk[2054*512:2054*512+700] = bytes(
            ((i*17)^(i>>2)^0x95)&255 for i in range(700))
        expected_disk[2054*512:2054*512+len(created_source)] = created_source
        if disk.read_bytes() != expected_disk:
            raise RuntimeError('RedSea deletion/reuse changed unexpected data or metadata')
        commands = [int(line.rsplit('cmd 0x', 1)[1], 16)
                    for line in ata_trace.read_text().splitlines()
                    if 'ide_bus_exec_cmd' in line and 'cmd 0x' in line]
        writes_flushes = [command for command in commands if command in (0x30, 0xE7)]
        expected_order = ([0x30,0x30,0x30,0xE7,0x30,0xE7] +
                          [0x30,0xE7,0x30,0xE7] + [0x30,0x30,0xE7,0x30,0xE7] +
                          [0xE7,0x30,0xE7,0x30,0xE7] + [0x30,0xE7])
        if writes_flushes[-len(expected_order):] != expected_order:
            raise RuntimeError('RedSea deletion lacks expected tombstone/bitmap flush ordering')
    if args.redsea_replace:
        expected_disk = bytearray(redsea_before)
        new_source = b'I64 Answer() { return 42; }\n'
        location = 2051*512+2*64
        expected_disk[location:location+64] = struct.pack(
            '<H38sqqQ', 0x822, b'Saved.HC', 2054, len(new_source), 12345)
        expected_disk[2055*512:2055*512+700] = bytes(
            ((i*17)^(i>>2)^0x95)&255 for i in range(700))
        expected_disk[2054*512:2054*512+len(new_source)] = new_source
        if disk.read_bytes() != expected_disk:
            raise RuntimeError('RedSea replacement differs from expected data/entry/reclaimed bitmap')
        commands = [int(line.rsplit('cmd 0x', 1)[1], 16)
                    for line in ata_trace.read_text().splitlines()
                    if 'ide_bus_exec_cmd' in line and 'cmd 0x' in line]
        writes_flushes = [command for command in commands if command in (0x30, 0xE7)]
        expected_order = ([0x30,0x30,0x30,0xE7,0x30,0xE7,0x30,0xE7] +
                          [0xE7,0x30,0xE7,0x30,0xE7] + [0x30,0x30,0xE7,0x30,0xE7])
        if writes_flushes[-len(expected_order):] != expected_order:
            raise RuntimeError('RedSea replacement lacks new-data/publication/old-release ordering')
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
        'ram_mib': 8, 'fault_cases': 5 if functions and not data_mode else 0, 'result': 'pass', 'recovered_exceptions': 3 if args.irq else 0, 'hash_vectors': 512 if args.hash else 0, 'soft_f64_vectors': 2048 if args.soft_f64 else 1024 if args.soft_f64_log or args.soft_f64_unary or args.soft_f64_convert or args.soft_f64_compare or args.soft_f64_to_int else 0, 'scope': 'Software Ln/Log10/Log2 with high-precision oracle and CR0.EM set' if args.soft_f64_log else 'Software F64 Abs/Sqr/Sqrt and integral rounding with x64 oracle and CR0.EM set' if args.soft_f64_unary else 'Integer math intrinsics against x64 and Python' if args.integer_math else 'Native HolyC F64 expressions with CR0.EM set' if args.float else 'Binary64 to I64/Bool and raw-bit truth testing with x64 compatibility and CR0.EM set' if args.soft_f64_to_int else 'Binary64 ordering with CR0.EM set' if args.soft_f64_compare else 'I64/U64 to binary64 with CR0.EM set' if args.soft_f64_convert else 'Binary64 add/subtract/multiply/divide bit patterns with CR0.EM set' if args.soft_f64 else 'Resident function/data binding for disk-loaded modules' if args.redsea_bind else 'RedSea linked module sets and dependency resolution' if args.redsea_load_set else 'RedSea module loading, execution and heap reclamation' if args.redsea_load else 'RedSea replacement and ordered old-extent reclamation' if args.redsea_replace else 'RedSea deletion, reclamation and reuse' if args.redsea_delete else 'RedSea file creation and publication ordering' if args.redsea_create else 'RedSea bitmap allocation, fragmentation and reclamation' if args.redsea_alloc else 'RedSea fixed-extent writes and partial failure reporting' if args.redsea_write else 'RedSea mount, directory lookup and raw file reads' if args.redsea else 'ATA identify, LBA28/CHS PIO reads/writes and cache flush' if args.ata else 'keyboard broker and task message delivery' if args.messages else 'blocking keyboard input and IRQ-driven task wakeups' if args.input else 'cooperative task contexts' if args.tasks else 'PIC/PIT/RTC/keyboard interrupts, input queue, exceptions and frame restoration' if args.irq else 'A20 methods and extended-memory allocation' if args.a20 else 'BIOS memory handoff and arena selection' if args.memory else 'Public exceptions across native task switches' if args.except_tasks else 'FS-bound public native exception runtime' if args.except_runtime else 'native exception capture and context transfer primitives' if args.except_context else 'native exception record ownership (no context transfer)' if args.except_records else 'Quoted-string decoding through shared and native readers' if args.lex_string else 'Lexer snapshot compatibility and native ownership' if args.lex_state else 'Shared compiler symbol layouts and legacy HashVal compatibility' if args.symbols else 'Native public hash primitives and shared record layouts' if args.hash else 'native arena heap' if args.heap else f'integer {kind} backend'}, indent=2)+'\n')
    print(f'PASS: {count} i386 {kind} cases generated by HolyC; instruction audit.')


if __name__ == '__main__':
    main()
