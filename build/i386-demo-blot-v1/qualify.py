"""Check the captured Blot square and compare the three raster color masks."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


COLORS = {
    'red': (168, 0, 0),
    'blue': (0, 0, 168),
    'yellow': (255, 255, 87),
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture(path, right):
    with Image.open(path) as image:
        pixels = image.convert('RGB').load()
        square = {(x, y) for y in range(80, 460) for x in range(right)
                  if pixels[x, y] == COLORS['yellow']}
        if not square:
            raise ValueError(f'Missing yellow square in {path}')
        x0 = min(x for x, _ in square)
        y0 = min(y for _, y in square)
        if square != {(x0 + x, y0 + y) for x in range(40) for y in range(40)}:
            raise ValueError(f'Expected a solid 40-by-40 square in {path}')
        # The reference terminal overlays blue text on the left of the image.
        # This common region avoids that text and the reference window's edge.
        if x0 < 140 or y0 < 100 or x0 + 40 > right or y0 + 120 > image.height:
            raise ValueError(f'Insufficient bitmap viewport in {path}')
        masks = {
            name: {(x, y) for y in range(-100, 120) for x in range(-140, 40)
                   if pixels[x0 + x, y0 + y] == color}
            for name, color in COLORS.items()
        }
    return [x0, y0], masks


def verify(run):
    receipt = json.loads((run / 'result.json').read_text())
    if receipt['result'] != 'pass' or not receipt['inputs_unchanged']:
        raise ValueError('Both guests must complete the demo')
    observed = {}
    raster = {}
    for side, right in (('original', 320), ('native', 640)):
        directory = run / side
        bitmap = directory / 'bitmap.png'
        cleared = directory / 'after-key.png'
        origin, masks = capture(bitmap, right)
        if min(len(masks[name]) for name in COLORS) < 200:
            raise ValueError(f'Missing raster component on {side}')
        with Image.open(cleared) as image:
            x, y = origin
            area = image.convert('RGB').crop((x, y, x + 40, y + 40))
            if area.getpixel((20, 20)) == COLORS['yellow']:
                raise ValueError(f'The yellow square did not clear on {side}')
        raster[side] = masks
        observed[side] = dict(square_origin=origin,
                              mask_pixels={name:len(mask) for name,mask in masks.items()},
                              bitmap_sha256=sha(bitmap), after_key_sha256=sha(cleared))
    changed = {name:len(raster['original'][name] ^ raster['native'][name])
               for name in COLORS}
    if any(changed.values()):
        raise ValueError(f'Normalized raster pixels differ: {changed}')
    return dict(result='pass', capture_receipt_sha256=sha(run / 'result.json'),
                differences=changed, observations=observed)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    print(json.dumps(verify(args.run), indent=2))


if __name__ == '__main__':
    main()
