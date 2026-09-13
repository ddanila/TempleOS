#!/usr/bin/env python3
"""Independently read the built filesystem and compare every archived OS path."""
import pathlib
import struct
import subprocess

root = pathlib.Path(__file__).resolve().parents[1]
image = (root / 'build/TempleOS.iso').read_bytes()
assert len(image) % 2048 == 0
for sector, kind in ((16, 1), (17, 0), (18, 2), (19, 255)):
    assert image[sector*2048:sector*2048+7] == bytes([kind]) + b'CD001\x01'
assert sum(struct.unpack_from('<16H', image, 20*2048)) & 0xffff == 0
assert image[20*2048+32] == 0x88
assert struct.unpack_from('<HI', image, 20*2048+38) == (4, 21)
assert image[18*2048+314:18*2048+330] == b'TempleOS RedSea\0'
assert image[88*512+3] == 0x88
assert struct.unpack_from('<H', image, 88*512+510)[0] == 0xaa55
_, sectors, root_block, bitmap_blocks, _ = struct.unpack_from('<5q', image, 88*512+8)
assert sectors == len(image)//512 - 88
files = {}
visited = set()


def visit(block):
    assert block not in visited, 'Directory cycle'
    visited.add(block)
    start = block*512
    attr, name, self_block, size, _ = struct.unpack_from('<H38sqqQ', image, start)
    assert attr & 16 and name.rstrip(b'\0') == b'.' and self_block == block
    assert size % 512 == 0 and start + size <= len(image)
    result = {}
    for pos in range(start+128, start+size, 64):
        attr, name, child, length, _ = struct.unpack_from('<H38sqqQ', image, pos)
        name = name.split(b'\0')[0].decode('ascii')
        if not name:
            break
        assert child*512 + length <= len(image)
        if attr & 16:
            for suffix, data in visit(child).items():
                result[name+'/'+suffix] = data
        else:
            result[name] = image[child*512:child*512+length]
    return result


files = visit(root_block)
paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', 'archive'],
                                cwd=root).decode().splitlines()
assert set(files) == set(paths)
for name in paths:
    assert files[name] == (root/name).read_bytes(), name
    # DolDoc records must fit exactly; this catches the archive's binary damage.
    if pathlib.Path(name).suffix in ('.HC', '.DD', '.MAP') and b'\0' in files[name]:
        data = files[name]
        pos = data.index(0)+1
        while pos < len(data):
            assert pos+16 <= len(data), name
            num, flags, size, uses = struct.unpack_from('<4I', data, pos)
            pos += 16+size
            assert pos <= len(data), name
        assert pos == len(data), name
print(f'Verified boot metadata, {len(visited)} directories, {len(files)} files, '
      'and embedded DolDoc record lengths.')
