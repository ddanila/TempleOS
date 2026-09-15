#!/usr/bin/env python3
"""Compare rebuilt x64 task metadata with the captured pre-extraction layout."""
import hashlib
import json
import re
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build/task-layout'


def run(*args):
    subprocess.run(args, cwd=ROOT, check=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'result.json').unlink(missing_ok=True)
    rebuild = json.loads((ROOT / 'build/rebuild-test/result.json').read_text())
    for name, digest in rebuild['source_sha256'].items():
        if hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != digest:
            raise ValueError(f'Rebuild is stale: {name}')
    iso = OUT / 'layout.iso'
    run(sys.executable, 'tools/build-iso.py', '--output', str(iso),
        '--overlay', 'build/rebuild-test/overlay', '--overlay', 'tests/guest/task-layout')
    run(sys.executable, 'tools/guest-run.py', str(iso), '--out', str(OUT / 'guest'))
    lines = (OUT / 'guest/debug.log').read_text().splitlines()
    sizes = [int(line.split()[2]) for line in lines if line.startswith('TASK SIZE ')]
    auxiliary = [list(map(int,line.split()[2:])) for line in lines if line.startswith('TASK AUX ')]
    fields = [line.split()[2:] for line in lines if line.startswith('TASK FIELD ')]
    actual = [[row[0], *map(int, row[1:])] for row in fields]
    fixture = ROOT / 'tests/fixtures/task-layout.json'
    layout = json.loads(fixture.read_text())
    expected = [[name, offset, size, pointers, count]
                for name, offset, size, _, _, pointers, count in layout]
    native = (ROOT / 'Kernel/I386/CompilerTaskLayoutProbe.HC').read_text()
    assertions = {name:int(offset) for name,offset in re.findall(r'#assert offset\(CTask\.(\w+)\)==(\d+)',native)}
    if assertions != {name:offset for name,_,_,offset,_,_,_ in layout if name!='pad'}:
        raise ValueError('Native offset assertions differ from the recorded layout contract')
    if sizes != [1192] or actual != expected or auxiliary != [[256,24,24,40,32]]:
        raise ValueError('Rebuilt x64 public CTask layout differs from its original fields')
    result = dict(result='pass', task_bytes=1192, fields=len(actual), auxiliary=auxiliary[0],
                  fixture_sha256=hashlib.sha256(fixture.read_bytes()).hexdigest(),
                  source_sha256=rebuild['source_sha256'],
                  inputs_sha256={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
                      for name in ('tools/check-task-layout.py','tests/guest/task-layout/Once.HC','tests/fixtures/task-layout.json')},
                  kernel_sha256=hashlib.sha256((ROOT / 'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C').read_bytes()).hexdigest())
    (OUT / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(f'PASS: all {len(actual)} original x64 CTask field layouts preserved')


if __name__ == '__main__':
    main()
