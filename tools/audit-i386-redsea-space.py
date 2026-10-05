#!/usr/bin/env python3
"""Report free and contiguous space after validating a writable RedSea image."""
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
    if args.out.exists():
        parser.error('Use a fresh report path')
    digest = hashlib.sha256(args.disk.read_bytes()).hexdigest()
    integrity = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](args.disk)
    image = args.disk.read_bytes()
    start, sectors, root, blocks, version = struct.unpack_from('<5q', image, 2048*512+8)
    first = start+blocks+1
    bitmap = image[(start+1)*512:first*512]
    free = run = best = extents = 0
    for block in range(first, start+sectors):
        index = block-(first-1)
        if not bitmap[index//8] & (1 << (index % 8)):
            if not run:
                extents += 1
            free += 1
            run += 1
            best = max(best, run)
        else:
            run = 0
    if hashlib.sha256(args.disk.read_bytes()).hexdigest() != digest:
        raise ValueError('Disk changed during audit')
    report = dict(result='pass', disk_sha256=digest, filesystem=integrity,
                  free_bytes=free*512, largest_free_extent_bytes=best*512,
                  free_extents=extents,
                  scope='Verified bitmap space; not proof a requested file operation succeeds')
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
