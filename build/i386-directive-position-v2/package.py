"""Install the cross-built warning renderer and matching source in a test image."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('base', type=Path)
parser.add_argument('candidate', type=Path)
args = parser.parse_args()
here = Path(__file__).resolve().parent
helper = runpy.run_path('tools/package-i386-native-image.py')
snapshot = helper['snapshot']
module = '/Modules/I386/CompilerRuntime.t32m'
replacements = {
    module: (here / 'exports/CompilerRuntime.t32m').read_bytes(),
    '/Compiler/I386/BackendCore.HC': (here / 'overlay/Compiler/I386/BackendCore.HC').read_bytes(),
}
original = snapshot(args.base.read_bytes())[1]
layout = runpy.run_path('tools/build-i386-kernel.py')['compiler_runtime_layout']
layout(original[module][2])
layout(replacements[module])


def updated(raw):
    tree, files, directories = snapshot(raw)
    for path, value in replacements.items():
        *parents, name = path[1:].split('/')
        folder = tree
        for directory in parents:
            folder = folder[directory][2]
        attr, date, _ = files[path]
        folder[name] = files[path] = (attr, date, value)
    return tree, files, directories


helper['package'].__globals__['snapshot'] = updated
report = helper['package'](args.base, args.candidate)
candidate = snapshot(args.candidate.read_bytes())[1]
if candidate.keys() != original.keys() or {
        path for path in original if candidate[path] != original[path]} != replacements.keys():
    raise ValueError('Unexpected file change in the warning renderer image')
report['replacements'] = {path: hashlib.sha256(data).hexdigest()
                          for path, data in replacements.items()}
(here / 'packaging.json').write_text(json.dumps(report, indent=2) + '\n')
