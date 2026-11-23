"""Reconcile native i386 backing regions with a physical startup heap census."""
import hashlib
import json
import struct
from pathlib import Path

root = Path(__file__).resolve().parent / 'high_v2'
physical = (root / 'memory.bin').read_bytes()
receipt = (root / 'result.json').read_bytes()
snapshot = json.loads(receipt)
assert snapshot['result'] == 'pass'
blocks = {
    block['address'] + 16: block
    for heap in snapshot['heaps'].values()
    for block in heap['blocks'] if not block['free']
}
headers = [
    match for match in range(len(physical))
    if physical.startswith(b'B32S\x00\x20\x00\x00', match)
]
signature, = headers
owner, fallback, cursor, _, quantum, count, retained = struct.unpack_from(
    '<6IQ', physical, signature - 12)
assert (owner, fallback) == (0x102538, 0x102550)
regions = {}
while cursor:
    assert cursor in blocks and cursor not in regions
    _, _, _, _, base, size, pool, used, following, request, span, hold = (
        struct.unpack_from('<5IQ6I', physical, cursor))
    assert base % 512 == size % 512 == 0 and used <= size
    assert base + size == cursor + request
    assert (request, span) == (blocks[cursor]['requested'], blocks[cursor]['span'])
    regions[cursor] = dict(pool=pool, size=size, used=used, span=span, reserve_hold=hold)
    cursor = following
assert len(regions) == count and sum(r['span'] for r in regions.values()) == retained
assert len({r['pool'] for r in regions.values()}) == 1
free = sorted((b for b in snapshot['heaps']['kernel']['blocks'] if b['free']),
              key=lambda b: b['span'], reverse=True)
start, end = sorted(free[:2], key=lambda b: b['address'])
between = [dict(b, backing=regions.get(address)) for address, b in blocks.items()
           if start['address'] + start['span'] <= b['address'] < end['address']]
print(json.dumps(dict(snapshot_sha256=hashlib.sha256(receipt).hexdigest(),
                      memory_sha256=hashlib.sha256(physical).hexdigest(),
                      owned_regions=count, quantum=quantum, retained=retained,
                      free_spans=[start, end], intervening_blocks=between), indent=2))
