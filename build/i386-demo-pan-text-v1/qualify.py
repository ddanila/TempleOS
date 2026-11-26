"""Verify horizontal and vertical text motion against the title glyphs."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

SOURCE = Path('Demo/Graphics/PanText.HC')
PURPLE = (168, 0, 168)
SAMPLES = 84


def sha(data):
    return hashlib.sha256(data).hexdigest()


def title(path, bounds=(8, 8, 630, 85)):
    with Image.open(path) as image:
        rgb = image.convert('RGB')
        left, top, right, bottom = bounds
        return {(x, y) for y in range(top, bottom) for x in range(left, right)
                if rgb.getpixel((x, y)) == PURPLE}


def origin(mask):
    return min(x for x, _ in mask), min(y for _, y in mask)


def offsets(root):
    reference = title(root / 'initial.png')
    if not reference:
        raise ValueError('Missing purple welcome title')
    # The original shows a second welcome window. Follow the first title.
    columns = sorted({x for x, _ in reference})
    right = next((a for a, b in zip(columns, columns[1:]) if b - a > 16), columns[-1])
    reference = {(x, y) for x, y in reference if x <= right}
    left, top = origin(reference)
    bounds = (left - 7, top - 7, right + 8, max(y for _, y in reference) + 8)
    moves = []
    for index in range(SAMPLES):
        frame = root / f'pan-{index:02d}.png'
        mask = title(frame, bounds)
        if not mask:
            moves.append(None)
            continue
        x, y = origin(mask)
        dx, dy = x - left, y - top
        if (max(abs(dx), abs(dy)) > 7 or
                {(i - dx, j - dy) for i, j in mask} != reference):
            moves.append(None)
            continue
        moves.append((dx, dy))
    if title(root / 'restored.png', bounds) != reference:
        raise ValueError('The original text position was not restored')
    usable = [(i, *move) for i, move in enumerate(moves) if move is not None]
    if len(usable) < SAMPLES // 2:
        raise ValueError('Too few complete title samples')
    x_moves = [x for _, x, y in usable]
    y_moves = [y for _, x, y in usable if x == 0]
    limits = [min(x_moves), max(x_moves), min(y_moves), max(y_moves)]
    if any(abs(value) < 3 for value in limits):
        raise ValueError('Both directions of each pan must be visible')
    horizontal = [i for i, dx, _ in usable if abs(dx) >= 3]
    vertical = [i for i, dx, dy in usable if dx == 0 and abs(dy) >= 3]
    if max(horizontal) >= min(vertical):
        raise ValueError('Horizontal and vertical phases occurred out of order')
    representatives = {
        'initial.png', 'restored.png',
        *(f'pan-{next(i for i, x, _ in usable if x == value):02d}.png' for value in limits[:2]),
        *(f'pan-{next(i for i, x, y in usable if x == 0 and y == value):02d}.png' for value in limits[2:]),
    }
    return dict(offsets=moves, incomplete_frames=SAMPLES - len(usable), extrema=limits, final_offset=[0, 0],
                frames_sha256={name: sha((root / name).read_bytes()) for name in sorted(representatives)})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    contract = json.loads((args.run / 'result.json').read_bytes())
    source = sha(SOURCE.read_bytes())
    if contract['result'] != 'captured' or not contract['inputs_unchanged'] or contract['source_sha256'] != source:
        raise ValueError('The unchanged demo did not finish on both guests')
    observations = {side: offsets(args.run / side) for side in ('original', 'native')}
    print(json.dumps(dict(result='pass', source_sha256=source,
                          input_sha256=contract['input_sha256'], runs=observations), indent=2))


if __name__ == '__main__':
    main()
