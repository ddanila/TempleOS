"""Recreate QEMU's raw PPM frames from verified PNGs."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


def ppm_from_png(path):
    with Image.open(path) as image:
        rgb = image.convert('RGB')
        return f'P6\n{rgb.width} {rgb.height}\n255\n'.encode('ascii') + rgb.tobytes()


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('manifest', type=Path)
    args = parser.parse_args()
    for line in args.manifest.read_text().splitlines():
        entry = json.loads(line)
        source, target = Path(entry['retained_png']), Path(entry['path'])
        data = ppm_from_png(source)
        if sha(source.read_bytes()) != entry['png_sha256'] or sha(data) != entry['ppm_sha256']:
            raise ValueError(f'Cannot verify the lossless recovery of {target}')
        if target.exists():
            if sha(target.read_bytes()) == entry['ppm_sha256']:
                continue
            raise FileExistsError(target)
        with target.open('xb') as restored:
            restored.write(data)


if __name__ == '__main__':
    main()
