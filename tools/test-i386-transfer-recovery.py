#!/usr/bin/env python3
"""Reboot independently constructed shared-extent transfer journal states."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]


def locate(image, path):
    root = struct.unpack_from('<q', image, 2048*512+24)[0]
    parent = root
    parts = path.strip('/').split('/')
    for index, name in enumerate(parts):
        size = struct.unpack_from('<q', image, parent*512+48)[0]
        found = None
        for slot in range(2, size//64):
            offset = parent*512+slot*64
            attr, raw, block, length, date = struct.unpack_from('<H38sqqQ', image, offset)
            text = raw.split(b'\0', 1)[0].decode('ascii')
            if not text:
                break
            if not attr & 0x100 and text == name:
                found = (parent, offset, attr, block, length, date)
                break
        if found is None:
            return None
        if index == len(parts)-1:
            return found
        if not found[2] & 0x10:
            raise ValueError('Invalid fixture parent')
        parent = found[3]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--case', action='append', choices=('intent', 'duplicate', 'committed', 'legacy-duplicate'))
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    dependencies = [args.disk, Path(__file__), ROOT/'tools/i386-kernel-input.py', ROOT/'tools/build-i386-kernel.py']
    pins = {str(p.resolve()): sha(p) for p in dependencies}
    report = {'result': 'fail', 'input_sha256': pins, 'cases': {},
              'scope': 'Independent transfer journal boundary reboot fixtures; not every device write interruption'}
    source_path = '/Kernel/I386/TextFrameDemo.HC'
    target_path = '/Probe/TransferRecovery.HC'
    original = args.disk.read_bytes()
    source = locate(original, source_path)
    directory = locate(original, '/Probe')
    if not source or not directory or source[2] != 0x800 or locate(original, target_path):
        raise ValueError('Invalid recovery fixture namespace')
    parent = directory[3]
    size = directory[4]
    slot = None
    for index in range(2, size//64-1):
        offset = parent*512+index*64
        if not original[offset+2] or original[offset+1] & 1:
            slot = offset
            break
    if slot is None:
        raise ValueError('Fixture needs an existing destination directory slot')
    root = struct.unpack_from('<q', original, 2048*512+24)[0]
    runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
    verify = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume']
    try:
        for case in args.case or ('intent', 'duplicate', 'committed', 'legacy-duplicate'):
            image = bytearray(original)
            header = 2048*512
            if any(image[header+48:header+192]):
                raise ValueError('Original disk already has a move journal')
            # Version-two shared extent journal, encoded independently of guest code.
            struct.pack_into('<6Q', image, header+56,
                             0 if source[0] == root else source[0],
                             0 if parent == root else parent,
                             source[3], source[4], source[5], source[2])
            image[header+104:header+142] = b'TextFrameDemo.HC'.ljust(38, b'\0')
            image[header+142:header+180] = b'TransferRecovery.HC'.ljust(38, b'\0')
            checksum = 0xCBF29CE484222325
            for byte in image[header+56:header+184]:
                checksum = ((checksum ^ byte) * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
            struct.pack_into('<Q', image, header+184, checksum)
            magic = 0x3245564F4D323349
            target_block = source[3]
            if case == 'legacy-duplicate':
                magic = 0x3145564F4D323349
                _, sectors, _, bitmap_blocks, _ = struct.unpack_from('<5q', image, header+8)
                first = 2048+bitmap_blocks+1
                count = (source[4]+511)//512
                run = 0
                for block in range(first, 2048+sectors):
                    bit = block-(first-1)
                    occupied = image[(2048+1)*512+bit//8] & (1 << (bit%8))
                    if occupied:run = 0
                    else:run += 1
                    if run == count:
                        target_block = block-count+1
                        break
                else:raise ValueError('Legacy fixture needs space for copied extent')
                for block in range(target_block, target_block+count):
                    bit = block-(first-1)
                    image[(2048+1)*512+bit//8] |= 1 << (bit%8)
                begin = source[3]*512
                image[target_block*512:target_block*512+source[4]] = original[begin:begin+source[4]]
            struct.pack_into('<Q', image, header+48, magic)
            if case != 'intent':
                struct.pack_into('<H38sqqQ', image, slot, source[2],
                                 b'TransferRecovery.HC'.ljust(38, b'\0'),
                                 target_block, source[4], source[5])
            if case == 'committed':
                image[source[1]+1] |= 1
            disk = args.out/(case+'.img')
            disk.write_bytes(image)
            behavior = runner(disk, args.out/case, snapshot=False, accel='kvm',
                ram_mib=8, startup_check={'status': 'ok', 'answers': [],
                                         'commands': [('6*7;', ['42'])]})
            after = disk.read_bytes()
            if any(after[header+48:header+192]):
                raise ValueError('Recovery did not clear intent')
            current = locate(after, source_path)
            moved = locate(after, target_path)
            if case == 'committed':
                if current is not None or moved is None or moved[2:] != source[2:]:
                    raise ValueError('Committed transfer did not preserve target extent')
            elif current != source or moved is not None:
                raise ValueError('Pending transfer did not roll back destination')
            block, length = source[3:5]
            if after[block*512:block*512+length] != original[block*512:block*512+length]:
                raise ValueError('Recovery changed shared payload')
            if after[:2048*512] != original[:2048*512]:
                raise ValueError('Recovery changed boot area')
            report['cases'][case] = dict(result='pass', behavior=behavior,
                                         filesystem=verify(disk), disk_sha256=sha(disk))
        if any(sha(Path(p)) != h for p, h in pins.items()):
            raise ValueError('Recovery qualification inputs changed')
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
