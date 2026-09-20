#!/usr/bin/env python3
"""Check rebuilt x64 document records against the original captured layout."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build/doc-layout'


def run(*args):
    subprocess.run(args, cwd=ROOT, check=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'result.json').unlink(missing_ok=True)
    rebuild = json.loads((ROOT / 'build/rebuild-test/result.json').read_text())
    for name, digest in rebuild['source_sha256'].items():
        if hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != digest:
            raise ValueError(f'Rebuild is stale: {name}')
    fixture = ROOT / 'tests/fixtures/doc-layout.json'
    contract = json.loads(fixture.read_text())
    iso = OUT / 'layout.iso'
    run(sys.executable, 'tools/build-iso.py', '--output', str(iso),
        '--overlay', 'build/rebuild-test/overlay', '--overlay', 'tests/guest/doc-layout')
    run(sys.executable, 'tools/guest-run.py', str(iso), '--out', str(OUT / 'guest'))
    lines = (OUT / 'guest/debug.log').read_text().splitlines()
    records = {}
    for line in lines:
        row = line.split()
        if row[:2] == ['DOC', 'RECORD']:
            if row[2] in records:
                raise ValueError('Duplicate document record')
            records[row[2]] = dict(size=int(row[3]), fields=[])
        elif row[:2] == ['DOC', 'FIELD']:
            records[row[2]]['fields'].append([row[3], *map(int, row[4:])])
    expected = {name:dict(size=record['x64_size'], fields=[field[:5] for field in record['fields']])
                for name,record in contract['records'].items()}
    if records != expected or lines.count('DOC BIN SPAN 16') != 1:
        raise ValueError('Original document layouts or saved binary span changed')
    assertions = []
    for name,record in contract['records'].items():
        assertions.append(f'#assert sizeof({name})=={record["i386_size"]}')
        for field,xoff,xsize,pointers,count,offset,size in record['fields']:
            assertions += [f'#assert offset({name}.{field})=={offset}',
                           f'#assert sizeof({name}.{field})=={size}']
    assertions.append('#assert offset(CDocBin.end)-offset(CDocBin.start)==16')
    actual = [line for line in (ROOT/'Kernel/I386/DocLayoutCheck.HH').read_text().splitlines()
              if line.startswith('#assert ')]
    if actual != [line+';' for line in assertions]:
        raise ValueError('Native document assertions differ from the layout contract')
    result = dict(result='pass', records=len(records), fields=sum(len(r['fields']) for r in records.values()),
                  binary_span_bytes=16, native_assertions=len(assertions), source_sha256=rebuild['source_sha256'],
                  inputs_sha256={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
                    for name in ('tools/check-doc-layout.py', 'tests/guest/doc-layout/Once.HC',
                                 'tests/fixtures/doc-layout.json')})
    (OUT/'result.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f'PASS: {result["records"]} document records, {result["fields"]} original x64 fields preserved')


if __name__ == '__main__':
    main()
