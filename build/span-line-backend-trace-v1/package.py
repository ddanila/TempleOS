import argparse
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('module', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
data = args.module.read_bytes()
build = runpy.run_path('tools/build-i386-kernel.py')
layout = build['compiler_runtime_layout'](data)
packer = runpy.run_path('tools/package-i386-native-image.py')
snapshot = packer['snapshot']
package = packer['package']
module_path = '/Modules/I386/CompilerRuntime.t32m'
original = snapshot(args.disk.read_bytes())[1]


def replace(raw):
    tree, files, directories = snapshot(raw)
    node = tree['Modules'][2]['I386'][2]
    attr, date, _ = node['CompilerRuntime.t32m']
    node['CompilerRuntime.t32m'] = files[module_path] = (attr, date, data)
    return tree, files, directories


target = args.out / 'kernel.img'
package.__globals__['snapshot'] = replace
try:
    receipt = package(args.disk, target)
finally:
    package.__globals__['snapshot'] = snapshot
files = snapshot(target.read_bytes())[1]
assert files.keys() == original.keys()
assert all(files[path] == v for path, v in original.items() if path != module_path)
assert files[module_path][2] == data
receipt['compiler_runtime_image_bytes'] = layout['image_bytes']
(args.out / 'result.json').write_text(json.dumps(receipt, indent=2) + '\n')
