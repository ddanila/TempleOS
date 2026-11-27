"""Recreate the integration image from the verified native boot and provider files."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'build/i386-demo-document-bounded-v1/cross'
SONG_SOURCE = '/Apps/Psalmody/PsalmodyFile.HC'
START = 2048 * 512


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('image', type=Path)
    args = parser.parse_args()
    base = (BASE / 'kernel.img').read_bytes()
    snapshot = runpy.run_path(str(ROOT / 'tools/package-i386-native-image.py'))['snapshot']
    volume = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['package_volume']
    with args.image.open('xb') as stream:
        stream.write(base[:START])
        stream.truncate(len(base))
    volume(args.image, BASE / 'exports', 'full')
    patched = args.image.read_bytes()
    before = snapshot(base)[1]
    after = snapshot(patched)[1]
    changed = sorted(name for name in before.keys() | after.keys()
                     if before.get(name) != after.get(name))
    if changed != [SONG_SOURCE] or base[:START] != patched[:START]:
        raise ValueError(f'Unexpected repackaging delta: {changed}')
    print(json.dumps({
        'base': str(BASE.relative_to(ROOT) / 'kernel.img'),
        'base_sha256': sha256(base).hexdigest(),
        'image_sha256': sha256(patched).hexdigest(),
        'changed_files': changed,
        'source_sha256': sha256(after[SONG_SOURCE][2]).hexdigest(),
    }, indent=2))


if __name__ == '__main__':
    main()
