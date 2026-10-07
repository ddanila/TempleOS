#!/usr/bin/env python3
"""Audit emitted direct-call loader frames against the diagnostic worker stack."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('module', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--stack-bytes', type=int, default=16384)
    parser.add_argument('--caller-reserve', type=int, default=6144,
                        help='2 KiB callers plus the existing 4 KiB parser reserve')
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    blob = args.module.read_bytes()
    runpy.run_path(str(ROOT/'tools/test-i386-retained-build.py'))['exports_of'](blob)
    _, payload, count, records, _ = struct.unpack_from('<5I', blob, 12)
    rows = [struct.unpack_from('<4I', blob, records+16*i) for i in range(count)]
    exports = sorted((offset, blob[name:name+length].decode('ascii'))
                     for kind, offset, name, length in rows if kind == 1)
    starts = [offset for offset, _ in exports]
    names = {name: offset for offset, name in exports}
    frames, calls = {}, {name: set() for name in names}
    for name, offset in names.items():
        code = blob[32+offset:32+offset+9]
        if code[:5] != bytes.fromhex('5589e581ec'):
            continue  # Only reachable functions need a recognized frame.
        frames[name] = struct.unpack_from('<I', code, 5)[0]
    disassemble = runpy.run_path(str(ROOT/'tools/test-i386.py'))['disassemble_i386']
    ranges = sorted((offset, offset+length) for kind, offset, length, _ in rows if kind == 4)
    relocations = {offset: blob[name:name+length].decode('ascii')
                   for kind, offset, name, length in rows if kind == 2}
    by_offset = {offset: name for offset, name in exports}
    inspected = set()
    argument_bytes = {}

    def inspect_calls(name):
        if name in inspected:
            return
        inspected.add(name)
        start = names[name]
        index = starts.index(start)
        end = starts[index+1] if index+1 < len(starts) else payload
        cursor = start
        segments = []
        for low, high in ranges:
            if high <= cursor or low >= end:
                continue
            if low > cursor:
                segments.append((cursor, min(low, end)))
            cursor = max(cursor, min(high, end))
        if cursor < end:
            segments.append((cursor, end))
        pops = set()
        for low, high in segments:
            for line in disassemble(blob[32+low:32+high]).splitlines():
                parts = line.split()
                if len(parts) >= 3 and parts[2] == 'ret':
                    pops.add(int(parts[-1], 0) if len(parts) > 3 else 0)
                if len(parts) < 4 or parts[2] != 'call' or not parts[3].startswith('0x'):
                    continue
                position = low+int(parts[0], 16)
                if blob[32+position] != 0xE8:
                    raise ValueError('Unsupported direct-call encoding')
                target = position+5+struct.unpack_from('<i', blob, 33+position)[0]
                if target == position+5 and 0x58 <= blob[32+target] <= 0x5F:
                    continue  # Balanced CALL-next/POP materializes an address.
                if position+1 in relocations:
                    target_name = relocations[position+1]
                elif target in by_offset:
                    target_name = by_offset[target]
                else:
                    raise ValueError(f'Unnamed direct loader call at {position:X} to {target:X}')
                calls[name].add(target_name)
        if len(pops) > 1:
            raise ValueError(f'Inconsistent argument cleanup: {name}')
        argument_bytes[name] = next(iter(pops), 0)

    def deepest(name, path=()):
        if name in path:
            raise ValueError(f'Recursive loader path: {path+(name,)}')
        if name not in frames:
            raise ValueError(f'Unrecognized or external loader frame: {name}')
        inspect_calls(name)
        best = (0, [])
        for target in calls[name]:
            candidate = deepest(target, path+(name,))
            if candidate[0] > best[0]:
                best = candidate
        # RET immediate measures the actual logical argument footprint. Add
        # return/EBP/saved-register linkage and an explicit transient allowance.
        return frames[name]+argument_bytes[name]+20+32+best[0], [name]+best[1]

    required, path = deepest('I386RedSeaLoadBound')
    result = dict(status='pass' if required+args.caller_reserve <= args.stack_bytes else 'fail',
                  scope='Emitted direct-call frames plus explicit caller/guard reserve; indirect callbacks require runtime qualification',
                  module=str(args.module.resolve()),
                  module_sha256=hashlib.sha256(blob).hexdigest(),
                  stack_bytes=args.stack_bytes, caller_reserve=args.caller_reserve,
                  loader_bytes=required, total_bytes=required+args.caller_reserve,
                  path=path, frames={name: frames[name] for name in path},
                  argument_bytes={name: argument_bytes[name] for name in path},
                  linkage_per_call=20, transient_allowance_per_call=32)
    args.out.mkdir(parents=True)
    (args.out/'result.json').write_text(json.dumps(result, indent=2)+'\n')
    print(f'{result["status"].upper()}: loader budget {result["total_bytes"]}/{args.stack_bytes} bytes')
    if result['status'] != 'pass':
        raise SystemExit(1)


if __name__ == '__main__':
    main()
