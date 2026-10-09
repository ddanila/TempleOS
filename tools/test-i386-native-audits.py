#!/usr/bin/env python3
"""Check strict host audits against persisted guest modules and damaged copies."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]


def check(name, module, audit):
    """Exercise the production disk audit with one real module and mutations."""
    path = '/Probe/Native' + {'bundle': 'Bundle', 'loader': 'Loader', 'alloc': 'Alloc', 'file': 'File'}[name] + '.t32m'
    namespace = audit.__globals__
    reader = namespace['mutated_file_contents']
    current = module
    try:
        namespace['mutated_file_contents'] = lambda disk, paths: {path: current}
        accepted = audit(None)
        _, _, count, records, _ = struct.unpack_from('<5I', module, 12)
        rows = [struct.unpack_from('<4I', module, records + 16 * i) for i in range(count)]
        call = next(row for row in rows if row[0] == 2)
        address = next(row for row in rows if row[0] == 5)
        export = next(row for row in rows if row[0] == 1)
        mutations = [('magic', 0), ('version', 4), ('cpu', 6),
                     ('pointer-size', 7), ('abi', 8), ('record-kind', records), ('export-name', export[2]),
                     ('call-opcode', 32 + call[1] - 1),
                     ('callback-opcode', 32 + address[1] - 1),
                     ('call-relocation', 32 + call[1]),
                     ('callback-relocation', 32 + address[1]),
                     ('name-terminator', export[2] + export[3]), ('record-count', 20)]
        rejected = []
        for label, offset in mutations:
            damaged = bytearray(module)
            damaged[offset] ^= 1
            current = bytes(damaged)
            try:
                audit(None)
            except ValueError:
                rejected.append(label)
            else:
                raise ValueError(f'{name} audit accepted {label} damage')
        return {'valid_fixture': 'pass', 'damage_rejections': rejected, 'audit': accepted}
    finally:
        namespace['mutated_file_contents'] = reader


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('bundle', 'loader', 'alloc'):
        parser.add_argument('--' + name, type=Path, required=True,
                            help='Persisted guest-built Native module file')
    parser.add_argument('--file', type=Path, help='Optional persisted NativeFile module')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    production = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))
    names = ('bundle', 'loader', 'alloc') + (('file',) if args.file else ())
    report = {'result': 'pass',
              'scope': 'Production host audits and thirteen damaged variants per real persisted fixture; not guest execution',
              'input_sha256': {str(path.resolve()): hashlib.sha256(path.read_bytes()).hexdigest()
                               for path in (Path(__file__), ROOT / 'tools/build-i386-kernel.py',
                                            *(getattr(args, name) for name in names))},
              'modules': {name: check(name, getattr(args, name).read_bytes(),
                                      production['verify_native_' + name + '_module'])
                          for name in names}}
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2) + '\n')
    print(f'PASS {len(names)} persisted fixtures and {13 * len(names)} damaged fixture rejections')


if __name__ == '__main__':
    main()
