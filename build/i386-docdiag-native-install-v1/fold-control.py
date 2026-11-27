from collections import Counter
from hashlib import sha256
import json
from pathlib import Path
from runpy import run_path
from struct import pack, pack_into, unpack_from
import sys

source, out = (Path(p).resolve() for p in sys.argv[1:])
raw = source.read_bytes()
packager = run_path('tools/package-i386-native-image.py')
snapshot = packager['snapshot']
path = '/Modules/I386/DocDiagnosticRuntime.t32m'
_, entries, directories = snapshot(raw)
module = entries[path][2]
size, count, records, strings = unpack_from('<4I', module, 16)
assert len(module) == unpack_from('<I', module, 12)[0]
assert records == 32 + size and strings == records + count * 16
rows = [unpack_from('<4I', module, records+i*16) for i in range(count)]
def name(row):
    return module[row[2]:row[2]+row[3]]
exports = {}
for row in rows:
    if row[0] in (1, 3):
        assert name(row) not in exports
        exports[name(row)] = row
payload = bytearray(module[32:records])
folded = Counter()
retained = []
for row in rows:
    kind, offset, _, _ = row
    if kind in (2, 5) and name(row) in exports:
        target_kind, target, _, _ = exports[name(row)]
        assert (kind, payload[offset-1]) in ((2, 0xe8), (5, 0x05))
        assert kind != 2 or target_kind == 1
        assert payload[offset:offset+4] == bytes(4)
        pack_into('<i', payload, offset, target-offset-4)
        folded[kind] += 1
    else:
        retained.append(row)
assert {name(r) for r in retained if r[0] in (2, 5)} == {b'SysTry',b'SysUntry'}
new_strings = records+16*len(retained)
text = bytearray()
serialized = bytearray()
for row in retained:
    kind, offset, start, length = row
    if kind in (1,2,3,5):
        start = new_strings + len(text)
        text += name(row) + b'\0'
    serialized += pack('<4I', kind, offset, start, length)
header = bytearray(module[:32])
pack_into('<5I',header,12,new_strings+len(text),size,len(retained),records,new_strings)
candidate = bytes(header+payload+serialized+text)
def substitute(data):
    tree, files, dirs = snapshot(data)
    if data == raw:
        node = tree
        for component in ('Modules','I386'):
            node = node[component][2]
        attr, date, _ = node['DocDiagnosticRuntime.t32m']
        node['DocDiagnosticRuntime.t32m'] = files[path] = (attr, date, candidate)
    return tree, files, dirs
package = packager['package']
package.__globals__['snapshot'] = substitute
receipt = package(source, out)
_, after, after_dirs = snapshot(out.read_bytes())
assert after_dirs == directories and after.keys() == entries.keys()
assert {p for p in after if after[p] != entries[p]} == {path}
receipt.update(original_module_bytes=len(module), folded_module_bytes=len(candidate),
               folded=dict(folded), original_module_sha256=sha256(module).hexdigest(),
               folded_module_sha256=sha256(candidate).hexdigest())
(out.parent/'fold-result.json').write_text(json.dumps(receipt, indent=2)+'\n')
