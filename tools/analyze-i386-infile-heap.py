#!/usr/bin/env python3
"""Audit public backing regions in a captured 8 MiB InFile heap."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    capture, out = args.capture.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output path')
    result_path, memory_path = capture/'result.json', capture/'memory.bin'
    image, log_path = capture/'working.img', capture/'debug.log'
    inputs = [result_path, memory_path, image, log_path, Path(__file__).resolve(),
              ROOT/'tools/build-i386-kernel.py']
    pins = {str(p): sha(p) for p in inputs}
    prior = json.loads(result_path.read_text())
    if prior.get('result') != 'captured' or not prior.get('inputs_unchanged') or prior['memory_sha256'] != sha(memory_path):
        raise ValueError('Capture or memory digest is invalid')
    memory = memory_path.read_bytes()
    if len(memory) != 8*1024*1024:
        raise ValueError('Expected exactly 8 MiB')
    read = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents']
    module = read(image, {'/Modules/I386/MemoryRuntime.t32m'})['/Modules/I386/MemoryRuntime.t32m']
    if hashlib.sha256(module).hexdigest() != prior['module_sha256']['/Modules/I386/MemoryRuntime.t32m']:
        raise ValueError('MemoryRuntime differs from capture')
    _, count, records = struct.unpack_from('<III', module, 16)
    offsets = []
    for i in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records+16*i)
        if kind == 3 and module[name:name+length] == b'memory_pool':
            offsets.append(offset)
    match = re.search(r'^MEMORY ([0-9A-Fa-f]+) ', log_path.read_text(), re.M)
    if len(offsets) != 1 or not match:
        raise ValueError('Missing unique memory-pool address')
    pool = int(match[1], 16)+8+offsets[0]
    if pool+0x558 > len(memory):
        raise ValueError('Pool outside snapshot')
    allocated, used = struct.unpack_from('<qq', memory, pool+8)
    regions_head, size, signature, region_count = struct.unpack_from('<4I', memory, pool+0x4fc)
    owned, backing_signature, quantum, owned_count = struct.unpack_from('<4I', memory, pool+0x540)
    retained = struct.unpack_from('<q', memory, pool+0x550)[0]
    if signature != 0x53323350 or backing_signature != 0x53323342 or allocated != size or used < 0:
        raise ValueError('Pool signature or counters invalid')
    blocks = {b['address']+16: b for b in prior['blocks'] if b['live']}
    found, rows = set(), []
    while owned:
        if owned in found or len(found) >= owned_count or owned+52 > len(memory):
            raise ValueError('Invalid owned-region chain')
        found.add(owned)
        next_region, last, kind, flags, base, extent, owner, in_use, next_owned, request, span, hold = struct.unpack_from('<5IQ6I', memory, owned)
        block = blocks.get(owned)
        if (not block or kind != 1 or flags or owner != pool or extent < 512 or extent & 511 or
                in_use > extent or in_use & 511 or hold > 1 or block['requested'] != request or
                block['span'] != span or base < owned+52 or base+extent > owned+request):
            raise ValueError('Invalid backing-region or allocation identity')
        rows.append({'address': owned, 'base': base, 'bytes': extent, 'used': in_use,
                     'request': request, 'span': span, 'reserve_hold': hold,
                     'next': next_region, 'last': last})
        owned = next_owned
    by_address = {r['address']: r for r in rows}
    linked, previous, cursor = set(), 0, regions_head
    while cursor:
        region = by_address.get(cursor)
        if not region or cursor in linked or region['last'] != previous:
            raise ValueError('Invalid public-region chain')
        linked.add(cursor); previous, cursor = cursor, region['next']
    if (linked != found or len(rows) != owned_count or len(rows) != region_count or
            sum(r['bytes'] for r in rows) != size or sum(r['used'] for r in rows) != used or
            sum(r['span'] for r in rows) != retained or regions_head not in found):
        raise ValueError('Pool/ownership accounting mismatch')
    magic, version, conventional, _, ebda, stage_begin, stage_end, flags = struct.unpack_from('<8I', memory, 0x5000)
    map_magic, map_version, map_count, complete = struct.unpack_from('<4I', memory, 0x5040)
    if (magic != 0x4d323349 or version != 1 or not flags & 1 or not 0 < conventional <= 640 or
            stage_begin != 0x10000 or stage_end < 0x10200 or stage_end & 511 or
            map_magic != 0x50324d49 or map_version != 1 or complete != 1 or not 1 <= map_count <= 32):
        raise ValueError('Invalid captured boot information')
    limit = min(conventional*1024, ebda or 0xa0000)
    entries = []
    for i in range(map_count):
        base, length, kind, attr = struct.unpack_from('<QQII', memory, 0x5050+24*i)
        if not length or base+length > 0xffffffffffffffff:
            raise ValueError('Invalid captured firmware map entry')
        entries.append((base, base+length, kind, attr))
    # Mirror the kernel's declared boot-stack reservation, then exclude every
    # non-usable firmware overlap. This is geometry, not a lifetime audit.
    barriers = [(0x88000, 0x90000)] + [(a, b) for a, b, kind, attr in entries if kind != 1 or attr != 1]
    candidates = []
    for a, b, kind, attr in entries:
        if kind != 1 or attr != 1:
            continue
        spans = [(max(a, stage_end), min(b, limit))]
        for lo, hi in barriers:
            split = []
            for x, y in spans:
                if lo >= y or hi <= x:
                    split.append((x, y))
                else:
                    split.extend([(x, min(y, lo)), (max(x, hi), y)])
            spans = split
        for x, y in spans:
            x = (x+7)&~7; y &= ~7
            if y-x >= 24:
                candidates.append((y-x, x))
    if not candidates:
        raise ValueError('No firmware-described conventional candidate')
    low_size, low_base = sorted(candidates, key=lambda x: (-x[0], x[1]))[0]
    out.parent.mkdir(parents=True, exist_ok=True)
    report = {'result': 'pass' , 'scope': '32-bit captured backing-region accounting after failure unwind; not proof that live allocations may be freed',
              'input_sha256': pins, 'pool_address': pool, 'quantum': quantum, 'allocated': allocated,
              'used': used, 'retained': retained, 'regions': rows,
              'unheld_empty_regions': sum(not r['used'] and not r['reserve_hold'] for r in rows),
              'conventional_candidate': {'base': low_base, 'bytes': low_size,
                  'scope': 'Firmware geometry with boot stack excluded; live low-memory ownership is not yet audited'},
              'inputs_unchanged': all(sha(Path(p)) == digest for p, digest in pins.items())}
    out.write_text(json.dumps(report, indent=2)+'\n')
    if not report['inputs_unchanged']:
        raise ValueError('Inputs changed')


if __name__ == '__main__':
    main()
