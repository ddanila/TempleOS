"""Package the current KeepAway source into the frozen full desktop image."""
import argparse
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
helper = runpy.run_path(str(ROOT / 'tools/package-i386-native-image.py'))
snapshot = helper['snapshot']
name = '/Apps/KeepAway/KeepAway.HC'
source = (ROOT / name[1:]).read_bytes()


def updated_snapshot(image):
    tree, files, directories = snapshot(image)
    attr, date, _ = files[name]
    files[name] = tree['Apps'][2]['KeepAway'][2]['KeepAway.HC'] = (attr, date, source)
    return tree, files, directories


helper['package'].__globals__['snapshot'] = updated_snapshot
helper['package'](args.disk, args.out)
before = snapshot(args.disk.read_bytes())[1]
after = snapshot(args.out.read_bytes())[1]
if set(before) != set(after) or [path for path in before if before[path] != after[path]] != [name]:
    raise ValueError('Expected only KeepAway source to change')
