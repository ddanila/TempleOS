#!/usr/bin/env python3
"""Discover the pinned original source inventory; never infer runtime compatibility."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = 'c26482bb6ad3f80106d28504ec5db3c6a360732c'
REPAIRS = 'ce055f205fc38536443289fb1cfc73632f6624f4'
ROOTS = ()  # Include the complete pinned tree, including boot files and root scripts.
INCLUDE = re.compile(rb'^\s*#include\s+["<]([^">]+)[">]', re.M)
PUBLIC = re.compile(rb'\bpublic\s+(?:(?:_extern|extern)\s+\w+\s+)?[A-Za-z_][\w*\s]*?\b([A-Za-z_]\w*)\s*\(')


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def discover():
    records = git('ls-tree', '-r', '-z', REFERENCE, '--', *ROOTS).split(b'\0')
    entries = []
    # One batch avoids launching a process for every original source file.
    repaired = {}
    for record in git('ls-tree', '-r', '-z', REPAIRS).split(b'\0'):
        if record:
            header, path = record.split(b'\t', 1)
            repaired[path.decode()] = header.split()[2].decode()
    metadata = []
    archived = {}
    for record in records:
        if not record:
            continue
        header, path = record.split(b'\t', 1)
        mode, kind, oid = header.split()
        if kind != b'blob':
            raise ValueError('Unexpected reference object: '+record.decode())
        archived[path.decode()] = oid.decode()
        metadata.append((path.decode(), repaired[path.decode()]))
    batch = subprocess.run(['git', 'cat-file', '--batch'], cwd=ROOT,
                           input=''.join(oid+'\n' for _, oid in metadata).encode(),
                           stdout=subprocess.PIPE, check=True).stdout
    offset = 0
    for path, oid in metadata:
        end = batch.index(b'\n', offset)
        actual, kind, size = batch[offset:end].split()
        if actual.decode() != oid or kind != b'blob':
            raise ValueError('Reference batch mismatch')
        start = end+1
        data = batch[start:start+int(size)]
        offset = start+int(size)+1
        suffix = Path(path).suffix.upper()
        source = suffix in ('.HC', '.HH')
        current = ROOT/path
        entries.append(dict(
            path=path, category=path.split('/')[0], archive_blob=archived[path], reference_blob=oid,
            reference_sha256=hashlib.sha256(data).hexdigest(), bytes=len(data),
            kind='source' if source else 'document' if suffix == '.DD' else 'asset',
            launch_candidate=source and (path.startswith('Demo/') or Path(path).name in ('Run.HC', 'Load.HC')),
            include_literals=sorted({x.decode('latin1') for x in INCLUDE.findall(data)}) if source else [],
            public_symbol_candidates=sorted({x.decode('ascii') for x in PUBLIC.findall(data)}) if source else [],
            source_at_discovery='missing' if not current.is_file() else 'identical' if current.read_bytes() == data else 'modified',
            compatibility='unqualified', reference_workflow=None, oracle=None, tests=[]))
    return dict(schema=2, reference_revision=REFERENCE, repair_revision=REPAIRS,
                scope='Every blob in the complete pinned original tree',
                discovery_limits='Launch and symbol candidates are lexical hints. Includes may use macros or runtime paths; dependencies and workflows require review. Source equality is not runtime compatibility.',
                counts=dict(Counter(e['category'] for e in entries)), entries=entries)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT/'docs/i386-compatibility-inventory.json')
    parser.add_argument('--check', action='store_true', help='Verify discovery fields and exhaustive reference coverage, preserving reviewed workflow fields')
    parser.add_argument('--require-qualified', action='store_true', help='Fail unless every required inventory item has workflow, oracle, tests and qualified status')
    args = parser.parse_args()
    fresh = discover()
    if args.check:
        existing = json.loads(args.output.read_text())
        reviewed = {'compatibility', 'reference_workflow', 'oracle', 'tests', 'source_at_discovery'}
        def discovery(d):
            return [{k:v for k,v in e.items() if k not in reviewed} for e in d['entries']]
        if any(existing.get(k) != fresh[k] for k in ('schema','reference_revision','repair_revision','scope','counts')) or discovery(existing) != discovery(fresh):
            raise SystemExit('FAIL: stale inventory or incomplete reference coverage; regenerate and review changes')
        report = existing
    else:
        if args.output.exists():
            raise SystemExit('Refusing to overwrite reviewed inventory; use a fresh output path')
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(fresh, indent=2)+'\n')
        report = fresh
    gaps = [e['path'] for e in report['entries'] if e['compatibility'] != 'qualified' or
            not all(e.get(k) for k in ('reference_workflow', 'oracle', 'tests'))]
    print(json.dumps(dict(reference=REFERENCE, repair_revision=REPAIRS, repaired_blobs=sum(e['archive_blob']!=e['reference_blob'] for e in report['entries']), files=len(report['entries']), counts=report['counts'], unqualified=len(gaps))))
    if args.require_qualified and gaps:
        raise SystemExit('FAIL: compatibility qualification gaps remain; first: '+gaps[0])


if __name__ == '__main__':
    main()
