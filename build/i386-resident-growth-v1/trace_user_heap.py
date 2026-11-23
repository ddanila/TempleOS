"""Locate startup backing regions before and after each User fixture command."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct


def trace(arenas, blocks, addresses):
    def read(address, size):
        for base, data in arenas:
            offset = address - base
            if 0 <= offset <= len(data) - size:
                return data[offset:offset + size]
        return b''

    primary_base, primary = arenas[0]
    rows = blocks(primary, primary_base)
    by_address = {row['address']: row for row in rows}
    regions = {}
    for address in addresses:
        block = by_address.get(address)
        if block is None or not block['used']:
            regions[str(address)] = {'occupied': False}
            continue
        fields = struct.unpack('<5IQ6I', read(address, 52))
        _, _, kind, flags, page, size, pool, used, _, request, span, _ = fields
        if (kind != 1 or flags or page % 512 or address + request < page + size
                or size != 8192 or request != block['requested'] or span != block['span']):
            raise ValueError(f'Unexpected separator at {address:#x}')
        region = {'occupied': True, 'used_pages': used // 512, 'pool': pool}
        if used == size:
            next_page, _, signature, pages = struct.unpack('<2I4sI', read(page, 16))
            if signature == b'MBUs' and pages == 16:
                seen = {page}
                while next_page not in seen:
                    data = read(next_page, 16)
                    if len(data) != 16:
                        break
                    if data[8:12] != b'MBUs':
                        owner = read(next_page - 40, 40)
                        if len(owner) == 40 and owner[4:8] == b'HcSV':
                            region['heap_control'] = next_page - 40
                            region['task'] = int.from_bytes(owner[36:40], 'little')
                        break
                    seen.add(next_page)
                    next_page = int.from_bytes(data[:4], 'little')
        regions[str(address)] = region
    return {'largest_payload': max(row['span'] - 16 for row in rows if not row['used']),
            'regions': regions}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    parser.add_argument('--address', required=True, action='append', type=lambda s: int(s, 0))
    args = parser.parse_args()
    args.out = args.out.resolve()
    args.out.mkdir()
    disk_sha = hashlib.sha256(args.disk.read_bytes()).hexdigest()
    user = runpy.run_path('tools/test-i386-user-startup.py')
    packer = runpy.run_path('tools/package-i386-native-image.py')
    disk = args.out / 'working.img'
    packer['package'](args.disk, disk, additions={'/UserStartup.HC': user['FIXTURE'].read_bytes()})
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    blocks = runpy.run_path('tools/observe-i386-heap-pressure.py')['blocks']
    guest = guest_type(disk, args.out / 'guest', True, ram_mib=8)
    report = {'result': 'fail', 'disk_sha256': disk_sha, 'stages': {}}
    try:
        log = guest.wait('DONE native kernel startup\n')
        markers = ('ARENA', 'TASK FALLBACK ARENA')
        ranges = [tuple(int(v, 16) for v in re.search(
            rf'^{marker} ([0-9A-F]+) ([0-9A-F]+)$', log, re.M).groups()) for marker in markers]
        stages = [('startup', None), *zip(
            ('public_header', 'report_definition', 'user_fixture'),
            (command for command, _ in user['COMMANDS'][:3]), strict=True)]
        for stage, command in stages:
            if command is not None:
                guest.command(command)
            guest.call('stop')
            try:
                arenas = []
                for name, (base, size) in zip(('main', 'fallback'), ranges, strict=True):
                    path = args.out / f'{stage}-{name}.bin'
                    guest.call('pmemsave', val=base, size=size, filename=str(path))
                    arenas.append((base, path.read_bytes()))
            finally:
                guest.call('cont')
            report['stages'][stage] = trace(arenas, blocks, args.address)
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        guest.close()
        (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
