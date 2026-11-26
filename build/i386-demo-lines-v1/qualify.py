"""Verify accumulation, animation and keypress cleanup in the seeded Lines demo."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

from PIL import Image

SOURCE = Path('Demo/Graphics/Lines.HC')
REGIONS = {'original': (8, 156, 312, 468), 'native': (0, 156, 640, 468)}
WHITE = (255, 255, 255)
FRAMES = ('before-key', 'before-key-1', 'before-key-2')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def pixels(path, side):
    with Image.open(path) as image:
        rgb = image.convert('RGB')
        if side == 'native':
            # Exclude the stationary managed mouse pointer.
            rgb.paste(WHITE, (320, 240, 329, 249))
        return rgb.crop(REGIONS[side]).get_flattened_data()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    capture = json.loads((args.run / 'result.json').read_bytes())
    if (capture['result'] != 'captured' or not capture['inputs_unchanged']
            or capture['seed'] != 1 or capture['source_sha256'] != sha(SOURCE.read_bytes())):
        raise ValueError('The seeded Lines demo did not complete on both guests')
    results = {}
    for side in ('original', 'native'):
        frames = [args.run / side / f'{stage}.png' for stage in FRAMES]
        samples = [pixels(frame, side) for frame in frames]
        histograms = [Counter(sample) for sample in samples]
        counts = [len(sample) - colors[WHITE] for sample, colors in zip(samples, histograms)]
        colors = [len(set(histogram) - {WHITE}) for histogram in histograms]
        changes = [sum(a != b for a, b in zip(left, right)) for left, right in zip(samples, samples[1:])]
        if min(counts) < 5000 or min(colors) < 2 or min(changes) < 100:
            raise ValueError(f'Expected an accumulating, multicolor drawing on {side}: {counts}, {colors}, {changes}')
        if counts != sorted(counts):
            raise ValueError(f'The drawing lost pixels before cleanup on {side}')
        after = args.run / side / 'after-key.png'
        if any(color != WHITE for color in pixels(after, side)):
            raise ValueError(f'The drawing did not clear after input on {side}')
        results[side] = dict(drawn_pixels=counts, drawing_colors=colors, changed_pixels=changes,
                             screenshots_sha256={frame.name: sha(frame.read_bytes()) for frame in (*frames, after)})
    print(json.dumps(dict(result='pass', seed=1, source_sha256=capture['source_sha256'],
                          input_sha256=capture['input_sha256'], runs=results), indent=2))


if __name__ == '__main__':
    main()
