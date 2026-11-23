"""Build a diagnostic image replacing selected retained modules."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('target', type=Path)
parser.add_argument('donor', type=Path)
parser.add_argument('--module', action='append', required=True)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
packer = runpy.run_path('tools/package-i386-native-image.py')
snapshot, package = packer['snapshot'], packer['package']
target, donor = [path.read_bytes() for path in (args.target, args.donor)]
_, original, _ = snapshot(target)
_, source, _ = snapshot(donor)
paths = {f'/Modules/I386/{name}.t32m' for name in args.module}
replacements = {name: source[name][2] for name in paths}

def replace_modules(raw):
    tree, files, directories = snapshot(raw)
    node = tree['Modules'][2]['I386'][2]
    for name, data in replacements.items():
        attributes, date, _ = original[name]
        files[name] = node[Path(name).name] = (attributes, date, data)
    return tree, files, directories

image = args.out / 'kernel.img'
package.__globals__['snapshot'] = replace_modules
try:
    report = package(args.target, image)
finally:
    package.__globals__['snapshot'] = snapshot
_, files, _ = snapshot(image.read_bytes())
assert files.keys() == original.keys()
assert all(files[name] == (attributes, date, replacements.get(name, data))
           for name, (attributes, date, data) in original.items())
assert target[:2048*512] == image.read_bytes()[:2048*512]
report.update(transplanted={name: hashlib.sha256(data).hexdigest()
                            for name, data in replacements.items()})
(args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
