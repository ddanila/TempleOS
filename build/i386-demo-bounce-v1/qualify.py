"""Check the bundled Bounce demo's colored trails and Escape cleanup."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

from PIL import Image


FRAMES = ('before-key', 'before-key-1', 'before-key-2', 'after-key')
TRAIL_COLORS = {(0, 168, 168), (168, 0, 168), (87, 87, 87), (87, 255, 87),
                (87, 255, 255), (255, 87, 87), (255, 87, 255), (255, 255, 87)}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check_frames(directory):
    frames = [directory / f'{name}.png' for name in FRAMES]
    pixels = []
    for frame in frames:
        with Image.open(frame) as image:
            pixels.append(list(image.convert('RGB').crop((16, 96, 272, 400)).getdata()))
    counts = [Counter(pixel for pixel in frame if pixel in TRAIL_COLORS) for frame in pixels]
    changes = [sum(a != b for a, b in zip(left, right))
               for left, right in zip(pixels[:2], pixels[1:3])]
    if any(sum(count.values()) < 1000 or len(count) < 6 for count in counts[:3]):
        raise ValueError(f'Missing multicolor trails in {directory}')
    if min(changes) < 500:
        raise ValueError(f'Trails did not change across samples in {directory}')
    if sum(counts[-1].values()) >= 100:
        raise ValueError(f'Trails remained after Escape in {directory}')
    return dict(trail_pixels=[sum(count.values()) for count in counts],
                trail_colors=[len(count) for count in counts],
                changed_pixels=changes,
                screenshots_sha256={path.name: sha(path) for path in frames})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    capture = json.loads((args.run / 'result.json').read_bytes())
    source = sha(Path('Demo/Graphics/Bounce.HC'))
    if (capture['result'] != 'captured' or capture['seed'] != 1
            or not capture['inputs_unchanged'] or capture['source_sha256'] != source):
        raise ValueError('Both guests must complete the unchanged demo with seed 1')
    results = {side: check_frames(args.run / side) for side in ('original', 'native')}
    print(json.dumps(dict(result='pass', source_sha256=source,
                          input_sha256=capture['input_sha256'], runs=results), indent=2))


if __name__ == '__main__':
    main()
