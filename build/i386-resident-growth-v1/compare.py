"""Compare resident module payloads and separate them from disk-only records."""

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import runpy
import struct


def measure(data):
    total, payload, count, records, strings = struct.unpack_from('<5I', data, 12)
    if (data[:4] != b'T32M' or total != len(data) or records != 32 + payload
            or strings != records + count * 16 or strings > total):
        raise ValueError('Invalid T32M layout')
    kinds = Counter()
    exports = set()
    declared_data = 0
    for i in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', data, records + 16 * i)
        kinds[kind] += 1
        if kind == 4:
            if offset + name > payload:
                raise ValueError('Data range extends beyond payload')
            declared_data += name
        elif kind in (1, 3):
            if offset >= payload or name < strings or name + length > total:
                raise ValueError('Invalid export')
            exports.add((kind, data[name:name + length]))
    return {'payload': payload, 'bytes': total, 'records': dict(sorted(kinds.items())),
            'declared_data_bytes': declared_data}, exports


def modules(snapshot, disk):
    raw = disk.read_bytes()
    files = snapshot(raw)[1]
    selected = {Path(name).stem: data for name, (_, _, data) in files.items()
                if name.startswith('/Modules/I386/') and name.endswith('.t32m')}
    return hashlib.sha256(raw).hexdigest(), selected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('cross', type=Path)
    parser.add_argument('retained', type=Path)
    args = parser.parse_args()
    snapshot = runpy.run_path('tools/package-i386-native-image.py')['snapshot']
    cross_sha, cross = modules(snapshot, args.cross)
    retained_sha, retained = modules(snapshot, args.retained)
    if cross.keys() != retained.keys():
        raise ValueError('Module sets differ')
    changes = {}
    for name in sorted(cross):
        before, before_exports = measure(cross[name])
        after, after_exports = measure(retained[name])
        if cross[name] != retained[name]:
            changes[name] = {'cross': before, 'retained': after,
                             'payload_growth': after['payload'] - before['payload'],
                             'removed_exports': [symbol.decode() for _, symbol in sorted(before_exports - after_exports)],
                             'added_exports': [symbol.decode() for _, symbol in sorted(after_exports - before_exports)]}
    print(json.dumps({'cross_sha256': cross_sha, 'retained_sha256': retained_sha,
                      'changes': changes,
                      'total_payload_growth': sum(c['payload_growth'] for c in changes.values())},
                     indent=2))


if __name__ == '__main__':
    main()
