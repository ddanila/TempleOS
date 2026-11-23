import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

parser = argparse.ArgumentParser()
parser.add_argument('base', type=Path)
parser.add_argument('console', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
overlay = Path(__file__).resolve().parent / 'overlay/Kernel/I386'
packer = runpy.run_path('tools/package-i386-native-image.py')
snapshot = packer['snapshot']
package = packer['package']
base_bytes = args.base.read_bytes()
original = snapshot(base_bytes)[1]
exports = args.out / 'exports'
exports.mkdir()
for name, value in original.items():
    if name.startswith('/Modules/I386/') and name.endswith('.t32m'):
        (exports / Path(name).name).write_bytes(value[2])
shutil.copyfile(args.console, exports / 'ConsoleRuntime.t32m')
shutil.copyfile(args.base.parent / 'exports/Kernel32.BIN', exports / 'Kernel32.BIN')
audit = runpy.run_path('tools/build-i386-kernel.py')
audit['console_runtime_layout'](args.console.read_bytes())
audit['audit'](exports, args.out)
replacements = {
    '/Modules/I386/ConsoleRuntime.t32m': args.console,
    '/Kernel/I386/ConsoleRuntime.HC': overlay / 'ConsoleRuntime.HC',
}
additions = {
    '/Kernel/I386/PublicGeometry.HH':(overlay/'PublicGeometry.HH').read_bytes(),
}


def replaced_snapshot(raw):
    tree, files, dirs = snapshot(raw)
    for name, path in replacements.items():
        parts = name.strip('/').split('/')
        node = tree
        for part in parts[:-1]:
            node = node[part][2]
        attr, date, _ = node[parts[-1]]
        node[parts[-1]] = (attr, date, path.read_bytes())
        files[name] = node[parts[-1]]
    return tree, files, dirs


image = args.out / 'kernel.img'
package.__globals__['snapshot'] = replaced_snapshot
try:
    report = package(args.base, image, additions=additions)
finally:
    package.__globals__['snapshot'] = snapshot
image_bytes = image.read_bytes()
files = snapshot(image_bytes)[1]
assert set(files) == set(original) | set(additions)
assert all(files[name] == value for name, value in original.items()
           if name not in replacements)
assert all(files[name][2] == path.read_bytes() for name, path in replacements.items())
assert all(files[name][2] == data for name, data in additions.items())
assert image_bytes[:2048 * 512] == base_bytes[:2048 * 512]
report.update(candidate_sha256=hashlib.sha256(image_bytes).hexdigest(),
              instruction_audit='pass')
(args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
