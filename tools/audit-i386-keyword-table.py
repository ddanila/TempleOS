#!/usr/bin/env python3
"""Check keyword descriptor semantics and deterministic name bytes in a T32M."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[1]


def audit(module):
    source = (ROOT/'Compiler/OpCodes.DD').read_bytes()
    rows = re.findall(rb'^(KEYWORD|ASM_KEYWORD)\s+(\w+)\s+(\d+)\s*;', source, re.M)
    if len(rows) != 73:
        raise ValueError('Changed keyword inventory')
    flags = (ROOT/'Kernel/HashFlags.HH').read_text()
    types = {name: int(value, 16) for name, value in re.findall(
        r'^#define\s+HTT_(KEYWORD|ASM_KEYWORD)\s+(0x[0-9A-Fa-f]+)', flags, re.M)}
    layout = (ROOT/'Compiler/KeywordTable.HH').read_text()
    if not re.search(r'class\s+CCompilerKeyword\s*\{\s*U8\s+name\[12\];\s*U32\s+type;\s*I64\s+value;\s*\}', layout):
        raise ValueError('Changed keyword descriptor layout')
    if len(module) < 32 or module[:4] != b'T32M':
        raise ValueError('Missing T32M header')
    total, payload, count, records, strings = struct.unpack_from('<5I', module, 12)
    if total != len(module) or records != 32+payload or strings != records+16*count or strings > total:
        raise ValueError('Invalid T32M layout')
    matches = []
    for i in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records+16*i)
        if kind == 3:
            if name < strings or length < 1 or name+length > total:
                raise ValueError('Invalid data export name')
            if module[name:name+length] == b'compiler_keywords':
                matches.append(offset)
    if len(matches) != 1 or matches[0]+24*len(rows) > payload:
        raise ValueError('Missing or invalid keyword descriptor export')
    table = module[32+matches[0]:32+matches[0]+24*len(rows)]
    for i, (kind, name, value) in enumerate(rows):
        expected = name + bytes(12-len(name))
        actual, actual_type, actual_value = struct.unpack_from('<12sIq', table, 24*i)
        if actual.split(b'\0', 1)[0] != name or actual_type != types[kind.decode()] or actual_value != int(value):
            raise ValueError('Keyword semantics differ: '+name.decode())
        if actual != expected:
            raise ValueError('Nonzero keyword name tail: '+name.decode())
    return {'result':'pass', 'keywords':len(rows),
            'table_sha256':hashlib.sha256(table).hexdigest(),
            'source_sha256':{name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
                             for name in ('Compiler/OpCodes.DD', 'Compiler/KeywordTable.HH', 'Kernel/HashFlags.HH')}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('module', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    data = args.module.read_bytes()
    report = {'result':'fail', 'module_sha256':hashlib.sha256(data).hexdigest(),
              'checker_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    try:
        report.update(audit(data))
    except Exception as error:
        report['error'] = str(error)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2)+'\n')
    print(report['result'], report.get('error', str(report.get('keywords'))+' keyword descriptors'))
    if report['result'] != 'pass':
        raise SystemExit(1)


if __name__ == '__main__':
    main()
