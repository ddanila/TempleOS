"""Match backing allocation history to the physical pre-User ownership chain."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import re
from runpy import run_path
import struct

ROOT = Path(__file__).resolve().parents[2]


def ownership(memory, log):
    provider = int(re.search(r'^MEMORY ([0-9A-F]+)', log, re.M)[1], 16)
    pool = provider + 8
    cursor, signature, _, count = struct.unpack_from('<4I', memory, pool + 0x544)
    assert signature == int.from_bytes(b'B32S', 'little')
    regions = {}
    while cursor:
        assert cursor not in regions and len(regions) < count
        base, size, owner, used, following = struct.unpack_from('<IqIII', memory, cursor + 16)
        assert owner == pool and used <= size and base + size <= len(memory)
        regions[cursor] = {'page_bytes': size, 'used_bytes': used}
        cursor = following
    assert len(regions) == count
    return regions


def replay(log):
    active = {}
    choice = None
    for line_number, line in enumerate(log.splitlines(), 1):
        if line == 'INPUT LINE USCheck;':
            assert choice is None
            return active
        if not line.startswith('BACKING '):
            continue
        _, event, *fields = line.split()
        values = [int(field, 16) for field in fields]
        if event == 'CHOICE':
            assert choice is None
            main_arena, size, request, retained = values
            choice = dict(line=line_number, main_arena=bool(main_arena), page_bytes=size,
                          request=request, retained=retained, fits=[])
        elif event == 'FIT':
            choice['fits'].append(values)
        elif event == 'LIMIT':
            largest, count = values
            assert count == len(choice['fits'])
            assert largest == max(span for _, span in choice['fits'])
        elif event == 'PICK':
            address, = values
            assert address not in active
            fits = [start for start, span in choice['fits'] if start <= address < start + span]
            assert len(fits) == 1
            choice['chosen_span_address'] = fits[0]
            active[address] = choice
            choice = None
        elif event == 'RELEASE':
            address, = values
            del active[address]
        else:
            raise ValueError(event)
    raise ValueError('Missing User command marker')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for item in ('image', 'log', 'memory'):
        parser.add_argument(item, type=Path)
    args = parser.parse_args()
    log = args.log.read_text()
    memory = args.memory.read_bytes()
    active = replay(log)
    regions = ownership(memory, log)
    assert active.keys() == regions.keys()
    assert all(active[address]['page_bytes'] == row['page_bytes'] for address, row in regions.items())
    analyze = run_path(str(ROOT / 'tools/profile-i386-startup-memory.py'))['analyze']
    blocks = analyze(args.image, log, memory)['blocks']
    first, last = sorted(sorted((i for i, block in enumerate(blocks) if not block['live']),
                                key=lambda i: -blocks[i]['span'])[:2])
    intervening = []
    for block in blocks[first + 1:last]:
        address = block['address'] + 16
        if address in regions:
            event = active[address]
            intervening.append(dict(payload_address=address, span=block['span'],
                                    **regions[address],
                                    allocation={k: v for k, v in event.items() if k != 'page_bytes'}))
        else:
            intervening.append(block)
    print(json.dumps({
        'scope': 'Allocation-time candidates for the live blocks between the two largest free spans.',
        'log_sha256': sha256(log.encode()).hexdigest(),
        'snapshot_sha256': sha256(memory).hexdigest(),
        'matched_live_regions': len(regions),
        'largest_free_spans': [blocks[first], blocks[last]],
        'intervening_blocks': intervening,
    }, indent=2))


if __name__ == '__main__':
    main()
