#!/usr/bin/env python3
"""Require cross-directory moves to retain data extents without file-sized free space."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    helper = ROOT/'tools/test-i386-transfer-recovery.py'
    dependencies = [args.disk, Path(__file__), helper, ROOT/'tools/i386-kernel-input.py', ROOT/'tools/build-i386-kernel.py']
    pins = {str(p.resolve()): sha(p) for p in dependencies}
    locate = runpy.run_path(str(helper))['locate']
    verify = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume']
    image = bytearray(args.disk.read_bytes())
    source_path = '/Modules/I386/ConsoleRuntime.t32m'
    target_path = '/Probe/MovedConsoleRuntime.t32m'
    source = locate(image, source_path)
    directory = locate(image, '/Probe')
    if not source or not directory or locate(image, target_path):raise ValueError('Invalid fixture namespace')
    start, sectors, root, blocks, version = struct.unpack_from('<5q', image, 2048*512+8)
    first = start+blocks+1
    bitmap_start = (start+1)*512
    bitmap_end = first*512
    run = best = reserve = 0
    for block in range(first, start+sectors):
        bit = block-(first-1)
        if image[bitmap_start+bit//8] & (1 << (bit%8)):run = 0
        else:
            run += 1
            if run > best:best = run; reserve = block-run+1
    if best*512 <= source[4]:raise ValueError('Fixture expects an initially usable large extent')
    slot = None
    for index in range(2, directory[4]//64-2):
        offset = directory[3]*512+index*64
        if not image[offset+2]:slot = offset; break
    if slot is None or locate(image, '/Probe/SpaceReserve.bin'):raise ValueError('No fixture reserve slot')
    count = best-1
    struct.pack_into('<H38sqqQ', image, slot, 0x800, b'SpaceReserve.bin'.ljust(38, b'\0'), reserve, count*512, 0)
    for block in range(reserve, reserve+count):
        bit = block-(first-1)
        image[bitmap_start+bit//8] |= 1 << (bit%8)
    largest = run = 0
    for block in range(first, start+sectors):
        bit = block-(first-1)
        if image[bitmap_start+bit//8] & (1 << (bit%8)):run = 0
        else:run += 1; largest = max(largest, run)
    if largest*512 >= source[4]:raise ValueError('Fixture still permits full-file copy')
    candidate = args.out/'candidate.img'
    candidate.write_bytes(image)
    report = {'result': 'fail', 'input_sha256': pins, 'source_bytes': source[4],
              'largest_free_extent_bytes': largest*512, 'initial_filesystem': verify(candidate),
              'scope': 'Low-space module move round trip, unchanged extent/payload/bitmap; not crash injection'}
    try:
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(candidate, args.out/'move', snapshot=False,
            accel='kvm', ram_mib=16, startup_check={'status': 'ok', 'answers': [],
                'commands': [(f'FileMove("C:{source_path}","C:{target_path}");', ['1']),
                             (f'FileMove("C:{target_path}","C:{source_path}");', ['1']),
                             ('6*7;', ['42'])]})
        after = candidate.read_bytes()
        if locate(after, source_path) != source or locate(after, target_path) is not None:
            raise ValueError('Round trip changed source extent or metadata')
        if after[bitmap_start:bitmap_end] != image[bitmap_start:bitmap_end]:raise ValueError('Move changed allocation bitmap')
        block, length = source[3:5]
        if after[block*512:block*512+length] != image[block*512:block*512+length]:raise ValueError('Move wrote payload')
        if after[:2048*512] != image[:2048*512]:raise ValueError('Move changed boot area')
        allowed = []
        for parent_block in (source[0], directory[3]):
            parent_size = struct.unpack_from('<q', image, parent_block*512+48)[0]
            allowed.append((parent_block*512, parent_block*512+parent_size))
        changed_sectors = set()
        for offset, (old, new) in enumerate(zip(image, after)):
            if old != new:
                if not any(begin <= offset < end for begin, end in allowed):
                    raise ValueError('Move changed bytes outside its two directories')
                changed_sectors.add(offset//512)
        report['changed_directory_sectors'] = sorted(changed_sectors)
        report['filesystem'] = verify(candidate)
        if any(sha(Path(p)) != h for p, h in pins.items()):raise ValueError('Inputs changed')
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:(args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':main()
