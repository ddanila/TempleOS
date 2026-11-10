#!/usr/bin/env python3
"""Compare two independently installed, fully guest-built i386 generations."""

import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

from i386_boot_area import expected_boot_area

ROOT = Path(__file__).resolve().parent.parent
BOOT_AREA = 2048 * 512


def kernel_date(module):
    if len(module) < 32 or module[:4] != b'T32M':
        raise ValueError('Malformed Kernel module')
    total, payload, count, records, strings = struct.unpack_from('<5I', module, 12)
    if (total != len(module) or records != 32 + payload or
            strings != records + 16 * count or strings > total):
        raise ValueError('Malformed Kernel module tables')
    offsets = []
    for index in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records + 16 * index)
        if kind == 3 and module[name:name + length] == b'kernel_compile_time':
            if offset + 8 > payload:
                raise ValueError('Kernel build date exceeds payload')
            offsets.append(offset)
    if len(offsets) != 1:
        raise ValueError('Expected one Kernel build date export')
    offset = offsets[0]
    timestamp = struct.unpack_from('<q', module, 32 + offset)[0]
    if timestamp <= 0:
        raise ValueError('Invalid Kernel build date')
    return offset, timestamp


def normalize_kernel_date(module, flat):
    offset, timestamp = kernel_date(module)
    if flat[8 + offset:16 + offset] != struct.pack('<q', timestamp):
        raise ValueError('Flat kernel build date differs from module')
    normalized_module, normalized_flat = bytearray(module), bytearray(flat)
    normalized_module[32 + offset:40 + offset] = bytes(8)
    normalized_flat[8 + offset:16 + offset] = bytes(8)
    return bytes(normalized_module), bytes(normalized_flat), timestamp


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--first', type=Path,
                        default=ROOT / 'build/i386-kernel/selfhost-install-fixed/target.img')
    parser.add_argument('--second', type=Path,
                        default=ROOT / 'build/i386-kernel/selfhost-install-gen2-fixed/target.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/generation-identity')
    parser.add_argument('--allow-kernel-build-date', action='store_true',
                        help='Compare all bytes except the exported eight-byte Kernel build date; verify each boot area independently')
    args = parser.parse_args()
    build = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))
    paths = {f'/Modules/I386/{name}.t32m' for name in build['DISK_MODULES']}
    paths.add('/Probe/GuestBoot.bin')
    files = build['mutated_file_contents']
    first = files(args.first, paths)
    second = files(args.second, paths)
    if set(first) != paths or set(second) != paths:
        raise ValueError('A generation is missing a guest-built module or flat image')
    dates = None
    comparable_first, comparable_second = dict(first), dict(second)
    if args.allow_kernel_build_date:
        kernel, flat = '/Modules/I386/Kernel.t32m', '/Probe/GuestBoot.bin'
        a, b, date_first = normalize_kernel_date(first[kernel], first[flat])
        c, d, date_second = normalize_kernel_date(second[kernel], second[flat])
        if date_second <= date_first:
            raise ValueError('Successive generation Kernel dates must increase')
        comparable_first.update({kernel: a, flat: b})
        comparable_second.update({kernel: c, flat: d})
        dates = [date_first, date_second]
    if any(comparable_first[path] != comparable_second[path] for path in paths):
        raise ValueError('Guest-built generation artifacts are not byte-identical')
    first_disk = args.first.read_bytes()
    second_disk = args.second.read_bytes()
    if args.allow_kernel_build_date:
        for disk, artifacts in ((first_disk, first), (second_disk, second)):
            if disk[:BOOT_AREA] != expected_boot_area(disk, artifacts['/Probe/GuestBoot.bin']):
                raise ValueError('Installed boot area differs from its actual flat kernel')
        if expected_boot_area(first_disk, comparable_first['/Probe/GuestBoot.bin']) != expected_boot_area(second_disk, comparable_second['/Probe/GuestBoot.bin']):
            raise ValueError('Boot areas differ beyond Kernel date and derived checksum')
    elif first_disk[:BOOT_AREA] != second_disk[:BOOT_AREA]:
        raise ValueError('Installed boot areas differ across generations')
    first_volume = build['verify_mutated_volume'](args.first)
    second_volume = build['verify_mutated_volume'](args.second)
    result = {'result': 'pass', 'module_count': len(paths) - 1,
              'flat_bytes': len(first['/Probe/GuestBoot.bin']),
              'flat_sha256': hashlib.sha256(first['/Probe/GuestBoot.bin']).hexdigest(),
              'boot_area_sha256': hashlib.sha256(first_disk[:BOOT_AREA]).hexdigest(),
              'first_volume': first_volume, 'second_volume': second_volume,
              'first_disk_sha256': hashlib.sha256(first_disk).hexdigest(),
              'second_disk_sha256': hashlib.sha256(second_disk).hexdigest()}
    result['comparison_scope'] = ('All artifact bytes except exported eight-byte Kernel date; '
                                  'each actual boot payload/checksum/padding verified independently'
                                  if dates else 'All artifact and boot-area bytes identical')
    if dates:
        result['kernel_build_dates'] = dates
        result['normalized_flat_sha256'] = hashlib.sha256(comparable_first['/Probe/GuestBoot.bin']).hexdigest()
    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(result)


if __name__ == '__main__':
    main()
