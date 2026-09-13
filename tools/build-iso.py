#!/usr/bin/env python3
"""Package this checkout as a bootable RedSea DVD; no downloads or recompilation.

Layout follows Adam/Opt/Boot/DskISORedSea.HC and Doc/RedSea.DD.
The existing kernel/compiler are the bootstrap for HolyC compilation in the VM.
"""
import argparse
import pathlib
import struct
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'build'
SECTOR = 512
DVD = 2048
OFFSET = 88  # RedSea starts after descriptors, catalog and loader.


def align(n, unit=SECTOR):
    return (n + unit - 1) // unit * unit


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=pathlib.Path, default=OUT / 'TempleOS.iso')
    parser.add_argument('--overlay', type=pathlib.Path, action='append', default=[],
                        help='Directory of guest paths to add/replace (last wins)')
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(exist_ok=True)
    # Archive identifies OS roots; include new versioned/unignored OS source too.
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only',
                                     'archive'], cwd=ROOT).decode().splitlines()
    os_dirs = {name.split("/")[0] for name in paths if "/" in name}
    additions = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT).decode().splitlines()
    paths = sorted(set(paths) | {name for name in additions
                                 if name.split("/")[0] in os_dirs})
    tree = {}
    for name in paths:
        node = tree
        parts = name.split('/')
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node[parts[-1]] = (ROOT / name).read_bytes()
    for overlay in args.overlay:
        for file in sorted(overlay.rglob('*')):
            if file.is_file():
                node = tree
                parts = file.relative_to(overlay).parts
                for part in parts[:-1]:
                    node = node.setdefault(part, {})
                node[parts[-1]] = file.read_bytes()
    tree.setdefault('Home', {})
    tree.setdefault('Tmp', {})['ScrnShots'] = {}

    def usage(node):
        if isinstance(node, bytes):
            return align(len(node), DVD)
        return align((len(node) + 3) * 64, DVD) + sum(map(usage, node.values()))

    blocks = usage(tree) // SECTOR
    bitmap_blocks = 1
    while (new := (blocks + bitmap_blocks + 1 + 4095) // 4096) != bitmap_blocks:
        bitmap_blocks = new
    cursor = align((OFFSET + 1 + bitmap_blocks) * SECTOR, DVD)
    image = bytearray(cursor + usage(tree))
    locations = {}

    def entry(name, attr, block, size):
        encoded = name.encode('ascii')
        if len(encoded) >= 38:
            raise ValueError(f'RedSea filename too long: {name}')
        return struct.pack('<H38sqqQ', attr, encoded, block, size, 0)

    def emit(node, path='', parent=None):
        nonlocal cursor
        start = cursor
        if isinstance(node, bytes):
            cursor += align(len(node), DVD)
            image[start:start + len(node)] = node
            locations[path] = (start // SECTOR, len(node))
            return start // SECTOR, len(node), 0x800
        size = align((len(node) + 3) * 64, DVD)
        cursor += size
        block = start // SECTOR
        entries = [entry('.', 0x810, block, size),
                   entry('..', 0x810, parent or block, 0)]
        for name, child in sorted(node.items()):
            child_block, child_size, attr = emit(child, path + '/' + name, block)
            entries.append(entry(name, attr, child_block, child_size))
        content = b''.join(entries)
        image[start:start + len(content)] = content
        return block, size, 0x810

    root_block, _, _ = emit(tree)
    total = len(image) // SECTOR
    boot = OFFSET * SECTOR
    image[boot + 3] = 0x88
    struct.pack_into('<5q', image, boot + 8, OFFSET, total - OFFSET,
                     root_block, bitmap_blocks, 1)
    struct.pack_into('<H', image, boot + 510, 0xaa55)
    # Bitmap indices start at data_area (see RedSeaInit/RedSeaAllocClus).
    allocated = total - (OFFSET + bitmap_blocks)
    bitmap = ((1 << allocated) - 1).to_bytes(bitmap_blocks * SECTOR, 'little')
    image[boot + SECTOR:boot + SECTOR + len(bitmap)] = bitmap

    def descriptor(kind):
        buf = bytearray(DVD)
        buf[:7] = bytes([kind]) + b'CD001\x01'
        return buf

    # TempleOS CISOPriDesc omits four ISO9660 path-table bytes: its root
    # and publisher offsets are 152 and 314, not standard ISO9660 offsets.
    primary = descriptor(1)
    struct.pack_into('<I', primary, 80, len(image) // DVD)
    struct.pack_into('>I', primary, 84, len(image) // DVD)
    for pos, value in ((120, 1), (124, 1), (128, DVD)):
        struct.pack_into('<H', primary, pos, value)
        struct.pack_into('>H', primary, pos + 2, value)
    struct.pack_into('<I', primary, 152, root_block)
    struct.pack_into('>I', primary, 156, root_block)
    primary[314:329] = b'TempleOS RedSea'
    primary[877] = 1
    image[16*DVD:17*DVD] = primary
    boot_desc = descriptor(0)
    boot_desc[7:31] = b'EL TORITO SPECIFICATION\0'
    struct.pack_into('<I', boot_desc, 71, 20)
    image[17*DVD:18*DVD] = boot_desc
    primary[0] = 2
    image[18*DVD:19*DVD] = primary
    image[19*DVD:20*DVD] = descriptor(255)
    catalog = bytearray(DVD)
    catalog[0] = 1
    catalog[4:12] = b'TempleOS'
    struct.pack_into('<H', catalog, 30, 0xaa55)
    checksum = -sum(struct.unpack('<16H', catalog[:32])) & 0xffff
    struct.pack_into('<H', catalog, 28, checksum)
    struct.pack_into('<BBHBBHI', catalog, 32, 0x88, 0, 0, 0, 0, 4, 21)
    image[20*DVD:21*DVD] = catalog
    kernel_block, kernel_size = locations['/0000Boot/0000Kernel.BIN.C']
    if kernel_size > 0x96600 - 0x7c00:
        raise ValueError('Kernel exceeds BIOS staging memory')
    subprocess.run(['nasm', '-f', 'bin', f'-DKERNEL_LBA={kernel_block // 4}',
                    f'-DKERNEL_BLOCKS={align(kernel_size, DVD) // DVD}',
                    str(ROOT / 'tools/boot-dvd.asm'), '-o', str(args.output.with_suffix('.boot.bin'))],
                   check=True)
    image[21*DVD:22*DVD] = args.output.with_suffix('.boot.bin').read_bytes()
    target = args.output
    assert len(image) == cursor and len(image) % DVD == 0
    temporary = target.with_suffix(target.suffix + '.tmp')
    temporary.write_bytes(image)
    temporary.replace(target)
    print(f'Built {target} ({len(image):,} bytes)')


if __name__ == '__main__':
    main()
