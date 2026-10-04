#!/usr/bin/env python3
"""Ensure dated ordinary/compressed files pass while metadata corruptions fail."""
import argparse
import json
from pathlib import Path
import runpy
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path, help='Image containing a dated file')
    parser.add_argument('--name', default='PublicWrite.BIN', help='Dated directory-entry filename')
    parser.add_argument('--builder', type=Path, default=ROOT/'tools/build-i386-kernel.py',
                        help='Auditor implementation to qualify, including an isolated port candidate')
    parser.add_argument('--resident', action='store_true', help='Require a resident fixture and reject resident metadata corruptions')
    args = parser.parse_args()
    verify = runpy.run_path(str(args.builder.resolve()))['verify_mutated_volume']
    original = args.disk.read_bytes()
    name = args.name.encode('ascii')
    if not name or len(name)>37 or '/' in args.name:
        parser.error('--name must be a single RedSea filename')
    marker = original.find(name+b'\0')
    offset = marker-2
    if marker<0 or offset%64 or not struct.unpack_from('<Q',original,offset+56)[0]:
        raise ValueError('Missing dated directory-entry fixture')
    baseline = verify(args.disk)
    if args.resident and struct.unpack_from('<H',original,offset)[0] not in (0xA00,0xE00):
        raise ValueError('Fixture is not a resident regular file')
    block = struct.unpack_from('<q',original,offset+40)[0]
    root = struct.unpack_from('<q',original,2048*512+24)[0]
    bitmap_blocks = struct.unpack_from('<q',original,2048*512+32)[0]
    first = 2048+bitmap_blocks+1
    mutations = {}
    bad = bytearray(original)
    struct.pack_into('<H',bad,offset,0xC02)
    mutations['unsupported-attributes'] = bad
    bad = bytearray(original)
    struct.pack_into('<H',bad,offset,0x400)
    mutations['noncontiguous-compressed'] = bad
    bad = bytearray(original)
    struct.pack_into('<q',bad,offset+40,root)
    mutations['overlap'] = bad
    bad = bytearray(original)
    struct.pack_into('<q',bad,offset+40,32768)
    mutations['outside-volume'] = bad
    bad = bytearray(original)
    index = block-(first-1)
    bad[2049*512+index//8] ^= 1<<(index%8)
    mutations['bitmap-disagreement'] = bad
    bad = bytearray(original)
    bad[offset+2] = ord('/')
    mutations['invalid-name'] = bad
    if args.resident:
        for name, attr in [('resident-unsupported-attributes',0xA02),
                           ('resident-noncontiguous',0x200),
                           ('resident-compressed-noncontiguous',0x600),
                           ('resident-deleted-live-extent',0xB00)]:
            bad = bytearray(original)
            struct.pack_into('<H',bad,offset,attr)
            mutations[name] = bad
    rejected = {}
    with tempfile.TemporaryDirectory() as directory:
        for name, data in mutations.items():
            path = Path(directory)/(name+'.img')
            path.write_bytes(data)
            try:
                verify(path)
            except ValueError as error:
                rejected[name] = str(error)
            else:
                raise AssertionError(f'Auditor accepted {name}')
    if args.disk.read_bytes()!=original:
        raise ValueError('Source fixture changed')
    print(json.dumps({'result':'pass','dated_volume':baseline,'filename':args.name,
                      'auditor':str(args.builder.resolve()),'resident':args.resident,
                      'rejected':rejected},indent=2))


if __name__=='__main__':
    main()
