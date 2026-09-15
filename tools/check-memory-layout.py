#!/usr/bin/env python3
"""Verify shared public memory records against their captured x64 layout."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build/memory-layout'


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'result.json').unlink(missing_ok=True)
    rebuild = json.loads((ROOT / 'build/rebuild-test/result.json').read_text())
    for name, digest in rebuild['source_sha256'].items():
        if hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != digest:
            raise ValueError(f'Rebuild is stale: {name}')
    fixture = ROOT / 'tests/fixtures/memory-layout.json'
    expected = json.loads(fixture.read_text())
    native = (ROOT / 'tests/guest/i386-heap/MemoryLayout.HC').read_text()
    assertions = {name: int(value) for name, value in re.findall(r'#assert sizeof\((\w+)\)==(\d+)', native)}
    offsets = {name: int(value) for name, value in re.findall(r'#assert offset\(([\w.]+)\)==(\d+)', native)}
    if assertions != {name: record['i386_size'] for name, record in expected.items()} or offsets != {
            f'{name}.{field}': offset for name, record in expected.items()
            for field, offset, *_ in record['i386_fields']}:
        raise ValueError('Native memory layout assertions differ from the captured target policy')
    iso = OUT / 'layout.iso'
    subprocess.run([sys.executable, 'tools/build-iso.py', '--output', str(iso),
                    '--overlay', 'build/rebuild-test/overlay', '--overlay', 'tests/guest/memory-layout'],
                   cwd=ROOT, check=True)
    subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out', str(OUT / 'guest')],
                   cwd=ROOT, check=True)
    actual = {}
    for line in (OUT / 'guest/debug.log').read_text().splitlines():
        words = line.split()
        if words[:2] == ['MEMORY', 'CLASS']:
            actual[words[2]] = dict(x64_size=int(words[3]), fields=[])
        if words[:2] == ['MEMORY', 'FIELD']:
            actual[words[2]]['fields'].append([words[3], *map(int, words[4:])])
    if actual != {name: {key: record[key] for key in ('x64_size', 'fields')}
                  for name, record in expected.items()}:
        raise ValueError('Public x64 memory layouts changed')
    result = dict(result='pass', classes=len(actual),
                  fields=sum(len(record['fields']) for record in actual.values()),
                  source_sha256=rebuild['source_sha256'],
                  inputs_sha256={name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in (
                      'tools/check-memory-layout.py', 'tests/fixtures/memory-layout.json',
                      'tests/guest/memory-layout/Once.HC', 'tests/guest/i386-heap/MemoryLayout.HC')})
    (OUT / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(f"PASS: {result['classes']} public memory records, {result['fields']} original x64 fields")


if __name__ == '__main__':
    main()
