"""Verify Extents' rendered bounding box and reported coordinates."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

from PIL import Image

SOURCE = Path('Demo/Graphics/Extents.HC')
BORDER = (255, 87, 87)
WHITE = (255, 255, 255)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def box_for(image):
    border = {(x, y) for y in range(150, 310) for x in range(130)
              if image.getpixel((x, y)) == BORDER}
    left = min(x for x, _ in border)
    right = max(x for x, _ in border)
    top = min(y for _, y in border)
    bottom = max(y for _, y in border)
    edges = {(x, y) for x in range(left, right + 1) for y in (top, bottom)}
    edges.update((x, y) for y in range(top, bottom + 1) for x in (left, right))
    if border != edges or (right - left + 1, bottom - top + 1) != (62, 36):
        raise ValueError('Unexpected size or outline for the bounding box')
    return left, top, right + 1, bottom + 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    capture = json.loads((args.run / 'result.json').read_bytes())
    source = sha(SOURCE.read_bytes())
    if capture['result'] != 'captured' or not capture['inputs_unchanged'] or capture['source_sha256'] != source:
        raise ValueError('The unchanged demo did not complete on both guests')
    glyphs = runpy.run_path('tools/check-i386-autocomplete-numeric-pixels.py')
    font = glyphs['font_bytes']()
    drawings = {}
    screenshots = {}
    for side, column in (('original', 1), ('native', 0)):
        before = args.run / side / 'before-key.png'
        after = args.run / side / 'after-key.png'
        with Image.open(before) as image:
            rgb = image.convert('RGB')
            box = box_for(rgb)
            drawings[side] = rgb.crop(box).tobytes()
        with Image.open(after) as image:
            rgb = image.convert('RGB')
            if rgb.crop(box).getcolors(2) != [(62 * 36, WHITE)]:
                raise ValueError(f'The graphics region did not clear on {side}')
            pixels = rgb.load()
            if not any(glyphs['text_at'](pixels, font, b'X: -11 to 49', column, row)
                       and glyphs['text_at'](pixels, font, b'Y: -12 to 23', column, row + 1)
                       for row in range(8)):
                raise ValueError(f'The expected bounds were not reported on {side}')
        screenshots[side] = {path.name: sha(path.read_bytes()) for path in (before, after)}
    if drawings['original'] != drawings['native']:
        raise ValueError('The box and sprite rasters differ')
    print(json.dumps(dict(result='pass', source_sha256=source, input_sha256=capture['input_sha256'],
                          bounds={'x': [-11, 49], 'y': [-12, 23]}, box_size=[62, 36],
                          raster_sha256=sha(drawings['native']), screenshots_sha256=screenshots), indent=2))


if __name__ == '__main__':
    main()
