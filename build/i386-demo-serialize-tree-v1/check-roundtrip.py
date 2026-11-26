"""Check the tree reports and byte dumps emitted by the bundled SerializeTree."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct

DIVIDER = re.compile(rb'\$FG,2\$\*{15}(?::\s*(\d+))?\$FG\$\n')
INDENT = re.compile(rb'\$ID,(-?\d+)\$')
ENTRY = re.compile(rb'\s*([\d,]+) \$(TR|LK),"([^"]+)"(?:,A="FI:([^"]*)")?\$')
DUMP_LINE = re.compile(rb'([0-9A-F]{8}) ((?:[0-9A-F]{2} ){1,16})')
RECORD = struct.Struct('<H38sqqq')
ARCHIVE_HEADER = struct.Struct('<qq')


def read_dump(text):
    data = bytearray()
    for line in text.split(b'\n'):
        if not line:
            continue
        match = DUMP_LINE.match(line)
        if not match or int(match[1], 16) != len(data):
            raise ValueError(f'Unexpected dump offset: {line[:8]!r}')
        data.extend(bytes.fromhex(match[2].decode('ascii')))
    return bytes(data)


def tree_rows(text):
    depth = 0
    rows = []
    for line in text.split(b'\n'):
        while match := INDENT.match(line):
            depth += int(match[1])
            line = line[match.end():]
        if line in (b'', b'\x05'):
            continue
        if not (match := ENTRY.fullmatch(line)):
            raise ValueError(f'Invalid tree row: {line!r}')
        count, kind, name, target = match.groups()
        rows.append((depth, kind, name, int(count.replace(b',', b'')), target))
    if depth:
        raise ValueError('Unbalanced report indentation')
    return rows


def decode_tree(data):
    def visit(offset, depth):
        while data[offset]:
            if data[offset] != 1:
                raise ValueError('Invalid directory record marker')
            attr, name, _, _, _ = RECORD.unpack_from(data, offset + 1)
            offset += 1 + RECORD.size
            is_dir = bool(attr & 16)
            rows.append((depth, b'TR' if is_dir else b'LK', name.split(b'\0', 1)[0]))
            if is_dir:
                offset = visit(offset, depth + 2)
        return offset + 1

    rows = []
    if visit(0, 0) != len(data):
        raise ValueError('Extra bytes after final directory record')
    return rows


def inspect_roundtrip(data):
    before, first_size, packed_text, size1, archive_text, size2, expanded_text, size3, after = DIVIDER.split(data)
    packed = read_dump(packed_text)
    archive = read_dump(archive_text)
    expanded = read_dump(expanded_text)
    if (first_size or packed != expanded or any(int(s) != len(packed) for s in (size1, size2, size3))
            or ARCHIVE_HEADER.unpack_from(archive) != (len(archive), len(packed))):
        raise ValueError('The archive sizes or expanded payload do not match')
    original = tree_rows(before)
    restored = tree_rows(after)
    decoded = decode_tree(packed)
    if [row[:3] for row in original] != decoded or [row[:3] for row in restored] != decoded:
        raise ValueError('The serialized records, original report and rebuilt report disagree')
    links = [(name, target) for _, kind, name, _, target in original if kind == b'LK']
    if any(not target or not target.endswith(b'/' + name) for name, target in links):
        raise ValueError('A source file link is missing its tree target')
    if any(count or target for _, _, _, count, target in restored):
        raise ValueError('The rebuilt report unexpectedly has line counts or link targets')
    receipt = dict(result='pass', document_sha256=hashlib.sha256(data).hexdigest(),
                   tree_sha256=hashlib.sha256(packed).hexdigest(), records=len(decoded),
                   file_links=len(links), serialized_bytes=len(packed),
                   archive_bytes=len(archive))
    return receipt, decoded


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('document', type=Path)
    parser.add_argument('--reference', type=Path)
    args = parser.parse_args()
    receipt, decoded = inspect_roundtrip(args.document.read_bytes())
    if args.reference:
        original, expected = inspect_roundtrip(args.reference.read_bytes())
        if decoded != expected:
            raise ValueError('The directory tree differs from the original guest')
        receipt['reference_document_sha256'] = original['document_sha256']
    print(json.dumps(receipt, indent=2))


if __name__ == '__main__':
    main()
