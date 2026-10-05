#!/usr/bin/env python3
"""Deterministically place a validated native RedSea tree without recompiling it."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]
START = 2048
RECORD = struct.Struct('<H38sqqQ')


def snapshot(image):
    """Read live entries, retaining file bytes, attributes and timestamps."""
    root = struct.unpack_from('<q', image, START * 512 + 24)[0]
    files = {}
    directories = {}

    def walk(block, path):
        attr, name, own, size, date = RECORD.unpack_from(image, block * 512)
        node = {}
        directories[path] = (attr, date)
        for offset in range(block * 512 + 128, block * 512 + size, 64):
            attr, raw, child, length, date = RECORD.unpack_from(image, offset)
            name = raw.split(b'\0', 1)[0].decode('ascii')
            if not name:
                break
            if attr & 0x100:
                continue
            child_path = path + '/' + name
            if attr == 0x810:
                subtree = walk(child, child_path)
                node[name] = (attr, date, subtree)
            else:
                data = image[child * 512:child * 512 + length] if length else b''
                files[child_path] = (attr, date, data)
                node[name] = (attr, date, data)
        return node

    return walk(root, ''), files, directories


def package(source, output):
    if output.exists() or source.resolve() == output.resolve():
        raise ValueError('Use a fresh output image; source images are immutable')
    helper = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))
    original = source.read_bytes()
    digest = hashlib.sha256(original).hexdigest()
    before = helper['verify_mutated_volume'](source)
    header = original[START * 512:(START + 1) * 512]
    if header[3] != 0x88 or header[510:] != b'\x55\xaa':
        raise ValueError('Invalid RedSea signature')
    if any(header[48:192]):
        raise ValueError('Recover pending journal before packaging')
    start, sectors, root, blocks, version = struct.unpack_from('<5q', header, 8)
    if len(original) != (start + sectors) * 512:
        raise ValueError('Unexpected native image size')
    tree, files, directories = snapshot(original)
    image = bytearray(len(original))
    image[:START * 512] = original[:START * 512]
    first = start + blocks + 1
    cursor = first

    def allocate(size):
        nonlocal cursor
        if not size:
            return 0
        block = cursor
        cursor += (size + 511) // 512
        if cursor > start + sectors:
            raise ValueError('Packed native tree exceeds volume')
        return block

    def record(name, attr, block, size, date):
        raw = name.encode('ascii')
        if not raw or len(raw) >= 38 or '/' in name:
            raise ValueError('Invalid native entry name')
        return RECORD.pack(attr, raw, block, size, date)

    def emit(node, parent=None):
        size = ((len(node) + 3) * 64 + 511) // 512 * 512
        block = allocate(size)
        rows = [record('.', 0x810, block, size, 0),
                record('..', 0x810, parent if parent is not None else block, 0, 0)]
        for name, (attr, date, child) in sorted(node.items()):
            if isinstance(child, dict):
                child_block, child_size = emit(child, block)
            else:
                child_size = len(child)
                child_block = allocate(child_size)
                image[child_block * 512:child_block * 512 + child_size] = child
            rows.append(record(name, attr, child_block, child_size, date))
        data = b''.join(rows)
        image[block * 512:block * 512 + len(data)] = data
        return block, size

    packed_root, _ = emit(tree)
    packed_header = bytearray(header)
    struct.pack_into('<q', packed_header, 24, packed_root)
    image[start * 512:(start + 1) * 512] = packed_header
    bitmap = bytearray(blocks * 512)
    for index in range(len(bitmap) * 8):
        block = first - 1 + index
        if block < cursor or block >= start + sectors:
            bitmap[index // 8] |= 1 << (index % 8)
    image[(start + 1) * 512:first * 512] = bitmap
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(image)
    after = helper['verify_mutated_volume'](output)
    _, packed_files, packed_directories = snapshot(output.read_bytes())
    if packed_files != files or packed_directories != directories:
        raise ValueError('Packaging changed native tree semantics')
    # Use the existing independent reader too, rather than only our own snapshot.
    if helper['mutated_file_contents'](output, set(files)) != {
            name: value[2] for name, value in files.items()}:
        raise ValueError('Independent reader rejected packaged file contents')
    if source.read_bytes() != original:
        raise ValueError('Source image changed during packaging')
    return dict(result='pass', source_sha256=digest,
                image_sha256=hashlib.sha256(image).hexdigest(),
                boot_area_sha256=hashlib.sha256(image[:START * 512]).hexdigest(),
                source_filesystem=before, packaged_filesystem=after,
                source_unchanged=True,
                scope='Sorted live tree placement; preserves all file bytes, attributes, dates and native boot area; not runtime qualification')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    report = package(args.source, args.out)
    args.out.with_suffix(args.out.suffix + '.json').write_text(
        json.dumps(report, indent=2) + '\n')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
