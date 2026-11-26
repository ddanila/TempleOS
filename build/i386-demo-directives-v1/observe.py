"""Record compiler directive and instruction-link behavior from a DolDoc capture."""
import argparse
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re


def observe(data, drive):
    if not data.endswith(b'\x05'):
        raise ValueError('Missing DolDoc end marker')
    rows = dict(line.decode('ascii').split('\t:', 1)
                for line in data[:-1].splitlines())
    if set(rows) != {'Date', 'Time', 'File', 'Dir', 'Line', 'CmdLine', 'Inst1', 'Inst2'}:
        raise ValueError('Unexpected directive output fields')
    datetime.strptime(rows['Date']+' '+rows['Time'], '%m/%d/%y %H:%M:%S')
    expected = {'File': drive+':/Demo/Directives.HC', 'Dir': drive+':/Demo', 'Line': '7', 'CmdLine': '0'}
    if any(rows[k] != v for k, v in expected.items()):
        raise ValueError('Incorrect source metadata')
    instructions = []
    for name in ('Inst1', 'Inst2'):
        match = re.fullmatch(
            r'\$LK,"&Directives\+0x([0-9A-F]+)",A="AD:0x([0-9A-F]+)"\$:([0-9A-F]+)',
            rows[name])
        if not match:
            raise ValueError(f'Missing instruction link in {name}: {rows[name]!r}')
        offset, target, address = [int(field, 16) for field in match.groups()]
        instructions.append({'offset': offset, 'target': target, 'address': address})
    first, second = instructions
    if first['target'] - first['offset'] != second['target'] - second['offset']:
        raise ValueError('Instruction links resolve to different functions')
    if not first['address'] < second['address']:
        raise ValueError('Instruction addresses are not in source order')
    return {'sha256': hashlib.sha256(data).hexdigest(), 'fields': rows, 'instructions': instructions}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('document', type=Path)
    parser.add_argument('drive')
    args = parser.parse_args()
    print(json.dumps({'result': 'pass', **observe(args.document.read_bytes(), args.drive)}, indent=2))
