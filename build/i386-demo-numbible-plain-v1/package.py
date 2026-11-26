"""Package the current NumBible source into the frozen full desktop image."""
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
name = '/Demo/DolDoc/NumBible.HC'
source = (ROOT / name[1:]).read_bytes()


def updated_snapshot(image):
    tree, files, directories = snapshot(image)
    attr, date, _ = files[name]
    files[name] = tree['Demo'][2]['DolDoc'][2]['NumBible.HC'] = (attr, date, source)
    return tree, files, directories


helper['package'].__globals__['snapshot'] = updated_snapshot
helper['package'](args.disk, args.out)
before = snapshot(args.disk.read_bytes())[1]
after = snapshot(args.out.read_bytes())[1]
if set(before) != set(after) or [path for path in before if before[path] != after[path]] != [name]:
    raise ValueError('Expected only NumBible source to change')
