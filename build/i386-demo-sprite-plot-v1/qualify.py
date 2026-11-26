"""Verify the terminal SpritePlot pose and its removal after a physical key."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

from PIL import Image

SOURCE = Path('Demo/Graphics/SpritePlot.HC')
WHITE = (255, 255, 255)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def pose_box(image):
    positions = []
    for y in range(100, 350):
        for x in range(80, 260):
            red, green, blue = image.getpixel((x, y))
            if red == green and red >= 165 and red - blue >= 75:
                positions.append((x, y))
    if len(positions) != 1237:
        raise ValueError('Unexpected yellow sprite pixels')
    x = min(x for x, _ in positions)
    y = min(y for _, y in positions)
    return x - 60, y - 4, x + 104, y + 130


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    capture = json.loads((args.run / 'result.json').read_bytes())
    raw = SOURCE.read_bytes()
    if capture['result'] != 'captured' or not capture['inputs_unchanged'] or capture['source_sha256'] != sha(raw):
        raise ValueError('The demo did not complete on both guests')
    bins = runpy.run_path('build/i386-demo-sprite-ext-v1/qualify.py')['bins']
    _, records = bins(raw)
    if len(records) != 1 or len(records[0][3]) != 167:
        raise ValueError('Unexpected bundled sprite size')
    glyphs = runpy.run_path('tools/check-i386-autocomplete-numeric-pixels.py')
    font = glyphs['font_bytes']()
    poses = {}
    frames = {}
    for side, column, row in (('original', 1, 2), ('native', 0, 0)):
        before = args.run / side / 'before-key.png'
        after = args.run / side / 'after-key.png'
        with Image.open(before) as image:
            rgb = image.convert('RGB')
            if not glyphs['text_at'](rgb.load(), font, b'Image size:167', column, row):
                raise ValueError(f'Missing the sprite size report on {side}')
            box = pose_box(rgb)
            poses[side] = rgb.crop(box).tobytes()
        with Image.open(after) as image:
            if image.convert('RGB').crop(box).getcolors(2) != [(164 * 134, WHITE)]:
                raise ValueError(f'The sprite was not cleared on {side}')
        frames[side] = {path.name: sha(path.read_bytes()) for path in (before, after)}
    if poses['original'] != poses['native']:
        raise ValueError('The position-aligned pose rasters differ')
    print(json.dumps(dict(result='pass', source_sha256=sha(raw), input_sha256=capture['input_sha256'],
                          sprite_bytes=167, pose_raster_sha256=sha(poses['native']),
                          screenshot_sha256=frames, cleared_after_key=True), indent=2))


if __name__ == '__main__':
    main()
