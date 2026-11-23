"""Stage a source-only ToTheFront port at the real application entry point."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('base', type=Path)
parser.add_argument('probe', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
packer = runpy.run_path('tools/package-i386-native-image.py')
snapshot, package = packer['snapshot'], packer['package']
original_disk = args.base.read_bytes()
_, original, _ = snapshot(original_disk)
if args.probe.suffix == '.zst':
    probe_image = subprocess.check_output(['zstd', '-dc', str(args.probe)])
else:
    probe_image = args.probe.read_bytes()
_, probe, _ = snapshot(probe_image)
app = '/Apps/ToTheFront'
native = '/Kernel/I386'
replacements = {}
helpers = {
    'PublicGeometrySource.HC': 'NativeTTFGeometry.HC',
    'IntegerPrompt.HC': 'NativeTTFIntegerPrompt.HC',
    'TTFWrap.HC': 'NativeTTFWrap.HC',
    'TTFCurves.HC': 'NativeTTFCurves.HC',
    'TTFRange.HC': 'NativeTTFRange.HC',
    'TTFKeyPoll.HC': 'NativeTTFKeyPoll.HC',
}
additions = {f'{native}/{name}': probe[f'/{source}'][2] for source, name in helpers.items()}
guard = b'I386_PUBLIC_USER_INCLUDED'

def insert(data, anchor, text):
    if data.count(anchor) != 1:
        raise ValueError(f'Expected one source anchor {anchor!r}')
    return data.replace(anchor, text + anchor)

def conditional_body(stock, serial, declaration):
    # Pull the alternate body out of the verified serial source, retaining the
    # original function signature and the stock multicore path.
    start = stock.index(b'{\n', stock.index(declaration)) + 2
    end = stock.index(b'\n}', start)
    a = serial.index(b'{\n', serial.index(declaration)) + 2
    b = serial.index(b'\n}', a)
    return (stock[:start] + b'#ifdef ' + guard + b'\n' + serial[a:b] +
            b'\n#else\n' + stock[start:end] + b'\n#endif' + stock[end:])

visibility_name = f'{app}/TTFVis.HC'
visibility = original[visibility_name][2]
serial = probe['/TTFSerialVis.HC'][2]
for declaration in (b'Bool VisRecalc(', b'U0 VisRecalcMap('):
    visibility = conditional_body(visibility, serial, declaration)
replacements[visibility_name] = visibility

fire_name = f'{app}/TTFFire.HC'
fire = original[fire_name][2]
assert fire.count(b'tmpi!=*indirect_head') == 1
replacements[fire_name] = fire.replace(b'tmpi!=*indirect_head', b'tmpi!=&indirect_head')

load_name = f'{app}/Load.HC'
load = original[load_name][2]
def native_block(*lines):
    return b'#ifdef '+guard+b'\n'+b'\n'.join(lines)+b'\n#endif\n'
def include(name):
    return f'#include "{native}/{name}"'.encode('ascii')
load = insert(load, b'#include "TTFGlbls"', native_block(
    include(helpers['PublicGeometrySource.HC']), include(helpers['IntegerPrompt.HC']),
    include(helpers['TTFWrap.HC'])))
load = insert(load, b'#include "TTFDraw"', native_block(include(helpers['TTFCurves.HC'])))
load = insert(load, b'#include "ToTheFront"', native_block(
    include(helpers['TTFRange.HC']), include(helpers['TTFKeyPoll.HC']),
    b'if(!HashFind("ACInit",adam_task->hash_table,HTT_FUN))',
    b'  AdamFile("/Adam/AutoComplete/MakeAC.HC",FALSE);;',
    b'if(!HashFind("SettingsPush",adam_task->hash_table,HTT_FUN))',
    b'  AdamFile("/Adam/TaskSettings.HC",FALSE);;'))
replacements[load_name] = load

def updated_snapshot(raw):
    tree, files, directories = snapshot(raw)
    node = tree['Apps'][2]['ToTheFront'][2]
    for path, data in replacements.items():
        attributes, date, _ = files[path]
        files[path] = node[Path(path).name] = (attributes, date, data)
    return tree, files, directories

image = out/'kernel.img'
package.__globals__['snapshot'] = updated_snapshot
try:
    receipt = package(args.base, image, additions=additions)
finally:
    package.__globals__['snapshot'] = snapshot
final = image.read_bytes()
_, files, _ = snapshot(final)
assert final[:2048*512] == original_disk[:2048*512]
assert files.keys() == original.keys() | additions.keys()
assert all(files[name] == (attr, date, replacements.get(name, data))
           for name, (attr, date, data) in original.items())
assert all(files[name][2] == data for name, data in additions.items())
receipt['replaced_files'] = {name: hashlib.sha256(data).hexdigest()
                             for name, data in replacements.items()}
(out/'result.json').write_text(json.dumps(receipt, indent=2)+'\n')
for name, data in (replacements | additions).items():
    path = out/'sources'/name.removeprefix('/')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
