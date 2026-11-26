"""Verify the rotating and scaling wireframe and its disappearance on Space."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

SOURCE = Path('Demo/Graphics/Box.HC')
RED = (168, 0, 0)
FRAMES = ('before-key', 'before-key-1', 'before-key-2')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def red_pixels(frame, left, right):
    with Image.open(frame) as image:
        rgb = image.convert('RGB')
        return {(x, y) for y in range(72, 460) for x in range(left, right)
                if rgb.getpixel((x, y)) == RED}


def outline(mask):
    width = max(x for x, _ in mask) - min(x for x, _ in mask) + 1
    height = max(y for _, y in mask) - min(y for _, y in mask) + 1
    if width < 24 or height < 24 or len(mask) >= width * height // 5:
        raise ValueError('The expected thin wireframe is missing')
    return [width, height]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    capture = json.loads((args.run / 'result.json').read_bytes())
    source = sha(SOURCE.read_bytes())
    if capture['result'] != 'captured' or not capture['inputs_unchanged'] or capture['source_sha256'] != source:
        raise ValueError('Both guests must complete the unchanged demo')
    runs = {}
    for side, left, right in (('original', 8, 320), ('native', 0, 640)):
        frames = [args.run / side / f'{stage}.png' for stage in FRAMES]
        masks = [red_pixels(frame, left, right) for frame in frames]
        counts = [len(mask) for mask in masks]
        if min(counts) < 120:
            raise ValueError(f'Too few wireframe pixels on {side}')
        sizes = [outline(mask) for mask in masks]
        changes = [len(a ^ b) for a, b in zip(masks, masks[1:])]
        if min(changes) < 120 or len({tuple(size) for size in sizes}) < 2:
            raise ValueError(f'The wireframe did not rotate and change size on {side}')
        after = args.run / side / 'after-key.png'
        if red_pixels(after, left, right):
            raise ValueError(f'The wireframe did not disappear on {side}')
        runs[side] = dict(wireframe_pixels=counts, dimensions=sizes, changed_pixels=changes,
                          screenshots_sha256={p.name: sha(p.read_bytes()) for p in (*frames, after)})
    print(json.dumps(dict(result='pass', source_sha256=source, input_sha256=capture['input_sha256'],
                          runs=runs), indent=2))


if __name__ == '__main__':
    main()
