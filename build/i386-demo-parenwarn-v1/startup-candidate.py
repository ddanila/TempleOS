"""Publish the original option functions from native startup in a test image."""
import argparse
from pathlib import Path
import runpy

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
helper = runpy.run_path('tools/package-i386-native-image.py')
snapshot = helper['snapshot']
path = '/Kernel/I386/StartOS.HC'
library = '/Compiler/PrsOptions.HC'
startup_line = b'AdamFile("::/Compiler/PrsOptions.HC",FALSE);\n'


def with_options(data):
    tree, files, directories = snapshot(data)
    if library not in files:
        raise ValueError('Shared compiler options source is missing from the base image')
    attr, date, original = files[path]
    if startup_line in original:
        return tree, files, directories
    replacement = (attr, date, original + b'\n' + startup_line)
    files[path] = tree['Kernel'][2]['I386'][2]['StartOS.HC'] = replacement
    return tree, files, directories


helper['package'].__globals__['snapshot'] = with_options
helper['package'](args.disk, args.out)
original = snapshot(args.disk.read_bytes())[1]
candidate = snapshot(args.out.read_bytes())[1]
if set(original) != set(candidate) or [key for key in original if original[key] != candidate[key]] != [path]:
    raise ValueError('Expected only native startup source to change')
