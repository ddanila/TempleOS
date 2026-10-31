#!/usr/bin/env python3
"""Identify the two live graphics bodies in an 8 MiB popup heap capture."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    capture, out = args.capture.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output path')
    result_path, memory_path = capture/'result.json', capture/'memory.bin'
    audit_path, image, log = capture/'backing-audit.json', capture/'working.img', capture/'debug.log'
    inputs = [result_path, memory_path, audit_path, image, log, Path(__file__).resolve(), ROOT/'tools/build-i386-kernel.py']
    pins = {str(p): sha(p) for p in inputs}
    prior, backing = json.loads(result_path.read_text()), json.loads(audit_path.read_text())
    if prior['result'] != 'captured' or not prior['inputs_unchanged'] or prior['memory_sha256'] != sha(memory_path) or backing['result'] != 'pass' or not backing['inputs_unchanged']:
        raise ValueError('Unverified capture or backing audit')
    memory = memory_path.read_bytes()
    module_path = '/Modules/I386/ConsoleRuntime.t32m'
    module = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](image, {module_path})[module_path]
    if hashlib.sha256(module).hexdigest() != prior['module_sha256'][module_path]:
        raise ValueError('Console module mismatch')
    _, count, records = struct.unpack_from('<III', module, 16)
    names = {}
    for i in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records+16*i)
        symbol = module[name:name+length].decode('ascii')
        if kind == 3 and symbol in ('graphics_persistent', 'graphics_frame'):
            if symbol in names:
                raise ValueError('Duplicate graphics export')
            names[symbol] = offset
    match = re.search(r'^CONSOLE ([0-9A-Fa-f]+) ', log.read_text(), re.M)
    if set(names) != {'graphics_persistent', 'graphics_frame'} or not match:
        raise ValueError('Missing graphics exports or module address')
    base = int(match[1], 16)+8
    results = []
    for name, offset in names.items():
        dc = struct.unpack_from('<I', memory, base+offset)[0]
        # The target CDC.body offset is 0x164 in the published i386 layout.
        body = struct.unpack_from('<I', memory, dc+0x164)[0]
        regions = [r for r in backing['regions'] if r['base'] <= body and body+640*480 <= r['base']+r['bytes']]
        if len(regions) != 1 or regions[0]['used'] != regions[0]['bytes']:
            raise ValueError('Graphics body is not in one fully used region')
        results.append({'symbol': name, 'dc': dc, 'body': body, 'body_bytes': 640*480,
                        'region': regions[0]['address'], 'region_bytes': regions[0]['bytes']})
    if results[0]['region'] == results[1]['region']:
        raise ValueError('Graphics bodies unexpectedly share one region')
    if any(sha(Path(p)) != digest for p, digest in pins.items()):
        raise ValueError('Inputs changed during analysis')
    out.write_text(json.dumps({'result': 'pass', 'scope': 'Captured public graphics body ownership, not a reclamation proof',
                               'graphics': results, 'input_sha256': pins, 'inputs_unchanged': True}, indent=2)+'\n')

if __name__ == '__main__':
    main()
