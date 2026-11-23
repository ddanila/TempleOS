"""Inspect the heap regions separating the two largest free blocks."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct


def measure(directory):
    raw = (directory / 'main.bin').read_bytes()
    log = (directory / 'guest/debug.log').read_text()
    arena = re.search(r'^ARENA ([0-9A-F]+) ([0-9A-F]+)$', log, re.M)
    if not arena:
        raise ValueError('Missing arena coordinates')
    base, size = (int(value, 16) for value in arena.groups())
    if len(raw) != size:
        raise ValueError('Incomplete arena snapshot')
    parse = runpy.run_path('tools/observe-i386-heap-pressure.py')['blocks']
    blocks = parse(raw, base)
    largest = sorted((i for i, block in enumerate(blocks) if not block['used']),
                     key=lambda i: blocks[i]['span'], reverse=True)[:2]
    left, right = sorted(largest)
    separators = []
    for block in blocks[left + 1:right]:
        if not block['used']:
            continue
        offset = block['address'] - base
        fields = struct.unpack_from('<5IQ6I', raw, offset)
        _, _, kind, flags, address, size, _, used, _, requested, span, reserve = fields
        if (kind != 1 or flags or address % 512 or reserve or used != size
                or requested != block['requested'] or span != block['span']):
            raise ValueError('Expected a fully occupied public backing region')
        _, _, signature, pages = struct.unpack_from('<2I4sI', raw, address - base)
        if signature != b'MBUs' or pages * 512 != size:
            raise ValueError('Backing region does not contain one complete live page run')
        separators.append({'address': block['address'], 'span': span,
                           'payload_bytes': size, 'pages': pages})
    return {'snapshot_sha256': hashlib.sha256(raw).hexdigest(),
            'largest_free_payloads': [blocks[i]['span'] - 16 for i in largest],
            'separators': separators}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('cross', type=Path)
    parser.add_argument('retained', type=Path)
    args = parser.parse_args()
    print(json.dumps({'cross': measure(args.cross), 'retained': measure(args.retained)}, indent=2))


if __name__ == '__main__':
    main()
