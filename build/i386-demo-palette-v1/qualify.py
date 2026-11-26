"""Compare all sixteen Palette swatches throughout the original demo."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

SOURCE = Path('Demo/Graphics/Palette.HC')
STANDARD = [
    (0, 0, 0), (0, 0, 168), (0, 168, 0), (0, 168, 168),
    (168, 0, 0), (168, 0, 168), (168, 87, 0), (168, 168, 168),
    (87, 87, 87), (87, 87, 255), (87, 255, 87), (87, 255, 255),
    (255, 87, 87), (255, 87, 255), (255, 255, 87), (255, 255, 255),
]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def gray_palette():
    dac = [(65535 * index // 15) >> 10 for index in range(16)]
    return [((value << 2) | ((value & 1) * 3),) * 3 for value in dac]


def swatches(image, left, top):
    return [image.getpixel((left + 1, top + 8 * index)) for index in range(16)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    capture = json.loads((args.run / 'result.json').read_bytes())
    if capture['result'] != 'captured' or not capture['inputs_unchanged'] or capture['source_sha256'] != sha(SOURCE.read_bytes()):
        raise ValueError('The unchanged Palette demo did not complete on both guests')
    gray = gray_palette()
    expected = {'gray': gray, 'yellow': gray[:-1] + [(255, 255, 0)], 'restored': STANDARD}
    rasters = {}
    frames = {}
    for side, left in (('original', 8), ('native', 0)):
        rasters[side], frames[side] = {}, {}
        top = None
        for stage, palette in expected.items():
            path = args.run / side / f'{stage}.png'
            frames[side][stage] = sha(path.read_bytes())
            with Image.open(path) as image:
                rgb = image.convert('RGB')
                if top is None:
                    starts = [y for y in range(0, rgb.height - 128, 8)
                              if swatches(rgb, left, y) == gray]
                    if len(starts) != 1:
                        raise ValueError(f'Expected one grayscale swatch strip on {side}')
                    top = starts[0]
                if swatches(rgb, left, top) != palette:
                    raise ValueError(f'The {stage} palette differs on {side}')
                rasters[side][stage] = rgb.crop((left, top, left + 96, top + 128)).tobytes()
    if rasters['original'] != rasters['native']:
        raise ValueError('The aligned swatch and label rasters differ')
    print(json.dumps(dict(result='pass', source_sha256=capture['source_sha256'],
                          input_sha256=capture['input_sha256'], colors=len(STANDARD),
                          palettes=expected, screenshots_sha256=frames,
                          raster_sha256={stage: sha(data) for stage, data in rasters['native'].items()}),
                     indent=2))


if __name__ == '__main__':
    main()
