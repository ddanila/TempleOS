from pathlib import Path
from runpy import run_path
from struct import unpack_from
import json
import re

root = Path('/dev/shm/templeos-docdiag-memory')
candidate = Path('/dev/shm/templeos-exact-jit')
read = run_path('tools/build-i386-kernel.py')['mutated_file_contents']
analyze = run_path('tools/profile-i386-startup-memory.py')['analyze']
cases = {
    'qualified-older': (root, Path('build/i386-code-alloc-known-v1/native-generations128/gen2-install/candidate.img')),
    'before-extra-libraries': (root, root / 'before-extra-libraries.img'),
    'installed-full': (root, Path('/dev/shm/templeos-release-psalmody/generations/gen1-install/candidate.img')),
    'installed-patched': (candidate, candidate / 'installed-patched.img'),
    'source-cross': (candidate, candidate / 'cross/kernel.img'),
}
output = {}
for case, (source, image) in cases.items():
    location = source / case
    memory = (location / 'prompt.bin').read_bytes()
    log = (location / 'guest/debug.log').read_text()
    name = '/Modules/I386/MemoryRuntime.t32m'
    module = read(image, {name})[name]
    module_base = int(re.search(r'^MEMORY ([\dA-F]+) ', log, re.M)[1], 16) + 8
    _, count, records = unpack_from('<III', module, 16)
    exports = {}
    for index in range(count):
        kind, offset, name, length = unpack_from('<4I', module, records + 16 * index)
        if kind == 3:
            exports[module[name:name + length]] = module_base + offset
    pool = exports[b'memory_pool']
    addr, signature, _, region_count, retained = unpack_from('<4IQ', memory, pool + 1348)
    assert signature == int.from_bytes(b'B32S', 'little')
    data = analyze(image, log, memory)
    blocks = {}
    regions = {'main': [], 'fallback': []}
    for label, heap in [('main', data), ('fallback', data['fallback_heap'])]:
        for block in heap['blocks']:
            if block['live']:
                blocks[block['address'] + 16] = (label, block)
    for _ in range(region_count):
        label, block = blocks.pop(addr)
        _, _, kind, flags, base, size, owner, used, next_owned, request, span, hold = unpack_from(
            '<5IQ6I', memory, addr)
        assert kind == 1 and flags == 0 and owner == pool
        assert span == block['span'] and request == block['requested']
        assert base % 512 == 0 and 52 <= base - addr <= 563
        assert request == base + size - addr and used % 512 == 0 and used <= size and hold in (0, 1)
        regions[label].append(dict(base=base, page_bytes=size, used_bytes=used, span=span, reserve_hold=hold))
        addr = next_owned
    assert addr == 0 and sum(r['span'] for rows in regions.values() for r in rows) == retained
    assert sum(r['used_bytes'] for rows in regions.values() for r in rows) == unpack_from('<Q', memory, pool+16)[0]
    output[case] = {}
    for label, heap in [('main', data), ('fallback', data['fallback_heap'])]:
        rows = regions[label]
        output[case][label] = dict(
            heap_free_bytes=heap['capacity'] - heap['used'], largest_free=heap['largest_free'],
            backing_regions=len(rows), backing_pages_bytes=sum(r['page_bytes'] for r in rows),
            backing_unused_bytes=sum(r['page_bytes'] - r['used_bytes'] for r in rows),
            backing_overhead_bytes=sum(r['span'] - r['page_bytes'] for r in rows),
            empty_regions=sum(r['used_bytes'] == 0 for r in rows))
print(json.dumps(output, indent=2))
