import argparse
import difflib
import hashlib
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
original = Path('Adam/AMathODE.HC').read_bytes().splitlines(keepends=True)
serial = Path('build/strut-rk4-derivative-v1/SerialODE.HC').read_bytes().splitlines(keepends=True)
guard = b'I386_NATIVE_SERIAL_ODE'
shared = []
for code, i, j, k, l in difflib.SequenceMatcher(None, original, serial, autojunk=False).get_opcodes():
    if code == 'equal':
        shared.extend(original[i:j])
    elif code == 'delete':
        shared.extend([b'#ifndef ' + guard + b'\n', *original[i:j], b'#endif\n'])
    else:
        shared.extend([b'#ifdef ' + guard + b'\n', *serial[k:l]])
        if code == 'replace':
            shared.extend([b'#else\n', *original[i:j]])
        shared.append(b'#endif\n')
shared = b''.join(shared)
packer = runpy.run_path('tools/package-i386-native-image.py')
snapshot = packer['snapshot']
package = packer['package']
base = args.disk.read_bytes()
files = snapshot(base)[1]
adapter_name = '/Kernel/I386/NativeODE.HC'
adapter = files[adapter_name][2]
include = b'#include "/Kernel/I386/ODESerial.HC"'
assert adapter.count(include) == 1
adapter = adapter.replace(include, b'#define ' + guard + b'\n#include "/Adam/AMathODE.HC"')
replacements = {'/Adam/AMathODE.HC':shared, adapter_name:adapter}


def overlay(raw):
    tree, entries, dirs = snapshot(raw)
    for path, data in replacements.items():
        parts = path.strip('/').split('/')
        node = tree
        for part in parts[:-1]:
            node = node[part][2]
        attr, date, _ = node[parts[-1]]
        node[parts[-1]] = (attr, date, data)
        entries[path] = (attr, date, data)
    return tree, entries, dirs


target = out / 'kernel.img'
package.__globals__['snapshot'] = overlay
try:
    report = package(args.disk, target)
finally:
    package.__globals__['snapshot'] = snapshot
result = target.read_bytes()
repacked = snapshot(result)[1]
assert set(repacked) == set(files)
assert all(repacked[name] == value for name, value in files.items() if name not in replacements)
assert all(repacked[name][2] == value for name, value in replacements.items())
assert base[:2048*512] == result[:2048*512]
(out / 'AMathODE.HC').write_bytes(shared)
(out / 'NativeODE.HC').write_bytes(adapter)
report.update(candidate_sha256=hashlib.sha256(result).hexdigest(),
              replacement_sha256={p:hashlib.sha256(b).hexdigest() for p,b in replacements.items()})
(out / 'result.json').write_text(json.dumps(report,indent=2)+'\n')
