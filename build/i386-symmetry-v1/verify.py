"""Verify the original and i386 Symmetry demo rasters."""
import argparse
import json
from pathlib import Path

from PIL import Image


STROKES = {
    'first': ((100, 145, 205, 210), (420, 145, 545, 210)),
    'second': ((210, 273, 318, 330), (462, 273, 590, 330)),
}


def ink(frame, box):
    with Image.open(frame) as image:
        pixels = image.convert('RGB').load()
        return {(x, y) for x in range(box[0], box[2])
                for y in range(box[1], box[3]) if pixels[x, y] == (0, 0, 0)}


def pair(directory, frame, axis, length):
    paths = directory / 'guest'
    left, right = (ink(paths / (frame + '.png'), box) for box in STROKES[frame])
    assert len(left) == len(right) == length
    assert {(2 * axis - x, y) for x, y in left} == right
    for box in STROKES[frame]:
        assert not ink(paths / 'start.png', box)
        assert not ink(paths / 'cleared.png', box)
    return left, right


def verify(original, native):
    old, new = (json.loads((p / 'result.json').read_text()) for p in (original, native))
    assert old['result'] == new['result'] == 'pass'
    assert old['demo_sha256'] == new['demo_sha256']
    assert old['first_drag'] == new['first_drag']
    assert old['axis_drag'] == new['axis_drag']
    assert old['second_drag'] == new['second_drag']
    assert new['fresh_arithmetic']
    moved_axis = old['axis_drag'][0][0]
    assert moved_axis == old['axis_drag'][1][0]
    summary = {}
    for frame, axis, length in [('first', 320, 70), ('second', moved_axis, 72)]:
        assert pair(original, frame, axis, length) == pair(native, frame, axis, length)
        summary[frame] = dict(axis_x=axis, pixels_per_stroke=length, exact_masks=True)
    return dict(result='pass', demo_sha256=old['demo_sha256'], strokes=summary,
                clear_on_escape=True, native_arithmetic=new['fresh_arithmetic'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path)
    parser.add_argument('native', type=Path)
    args = parser.parse_args()
    print(json.dumps(verify(args.original, args.native), indent=2))
