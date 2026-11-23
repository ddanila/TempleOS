import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser()
parser.add_argument('base', type=Path)
parser.add_argument('--shared-multiply', action='store_true')
parser.add_argument('--out', type=Path, required=True)
parser.add_argument('--primary-minimum', action='store_true')
parser.add_argument('--reuse-small-holes', action='store_true')
args = parser.parse_args()
args.out.mkdir()
root = Path(__file__).resolve().parent
packer = runpy.run_path('tools/package-i386-native-image.py')
snapshot, package = packer['snapshot'], packer['package']
builder = runpy.run_path('tools/build-i386-kernel.py')
if args.reuse_small_holes and not args.primary_minimum:
    parser.error('--reuse-small-holes requires --primary-minimum')
if args.primary_minimum and not args.shared_multiply:
    parser.error('--primary-minimum requires --shared-multiply')
attempt = root / ('cross-shared-multiply' if args.shared_multiply else 'cross-explicit-branch')
if args.reuse_small_holes:
    attempt = root / 'cross-small-holes'
elif args.primary_minimum:
    attempt = root / 'cross-primary-minimum'
exports = attempt / 'exports'
runtime = exports / 'CompilerRuntime.t32m'
builder['compiler_runtime_layout'](runtime.read_bytes())
builder['audit'](exports, args.out)
overlay = (attempt if args.shared_multiply else root) / 'overlay'
replacements = {'/' + str(path.relative_to(overlay)): path.read_bytes()
                for path in overlay.rglob('*') if path.is_file()}
replacements['/Modules/I386/CompilerRuntime.t32m'] = runtime.read_bytes()
if args.primary_minimum:
    memory = (exports/'MemoryRuntime.t32m').read_bytes()
    builder['memory_runtime_layout'](memory)
    replacements['/Modules/I386/MemoryRuntime.t32m'] = memory
original = args.base.read_bytes()
reference = snapshot(original)[1]

def updated_snapshot(raw):
    tree, files, directories = snapshot(raw)
    for path, data in replacements.items():
        parts = path.strip('/').split('/')
        node = tree
        for part in parts[:-1]:
            node = node[part][2]
        attributes, date, _ = files[path]
        files[path] = node[parts[-1]] = (attributes, date, data)
    return tree, files, directories

image = args.out / 'kernel.img'
package.__globals__['snapshot'] = updated_snapshot
try:
    report = package(args.base, image)
finally:
    package.__globals__['snapshot'] = snapshot
final = image.read_bytes()
contents = snapshot(final)[1]
assert final[:2048 * 512] == original[:2048 * 512]
assert contents.keys() == reference.keys()
for name, (attributes, date, data) in reference.items():
    assert contents[name] == (attributes, date, replacements.get(name, data)), name
report.update(instruction_audit='pass',
              changed_files={name: hashlib.sha256(data).hexdigest()
                             for name, data in replacements.items()})
(args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
