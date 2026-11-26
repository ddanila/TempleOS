"""Check the animated SpritePlot3D mesh and its removal after a keypress."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

SOURCE = Path('Demo/Graphics/SpritePlot3D.HC')
VOLUME = (105, 150, 300, 320)
WHITE = (255, 255, 255)
FACE_COLORS = (
    {(168, 0, 0), (255, 87, 87)},
    {(0, 168, 0), (87, 255, 87)},
    {(0, 0, 168), (87, 87, 255)},
)
FRAMES = ('before-key', 'before-key-1', 'before-key-2')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def sample(path):
    with Image.open(path) as image:
        region = image.convert('RGB').crop(VOLUME)
        colors = region.getcolors(64)
        mask = {index for index, color in enumerate(region.get_flattened_data()) if color != WHITE}
    return colors, mask


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    capture = json.loads((args.run / 'result.json').read_bytes())
    if capture['result'] != 'captured' or not capture['inputs_unchanged'] or capture['source_sha256'] != sha(SOURCE.read_bytes()):
        raise ValueError('Both guest workflows must finish using the unchanged source')
    results = {}
    for side in ('original', 'native'):
        reports, masks = [], []
        for stage in FRAMES:
            frame = args.run / side / f'{stage}.png'
            colors, mask = sample(frame)
            observed = {color for _, color in colors}
            allowed = set.union(*FACE_COLORS, {WHITE, (0, 0, 0)})
            visible = sum(bool(observed & family) for family in FACE_COLORS)
            if not observed <= allowed or visible < 2 or not 4000 <= len(mask) <= 9000:
                raise ValueError(f'Unexpected rotating mesh in {frame}')
            masks.append(mask)
            reports.append(dict(pixels=len(mask), visible_color_families=visible,
                                screenshot_sha256=sha(frame.read_bytes())))
        variation = [len(left ^ right) for left, right in zip(masks, masks[1:])]
        if min(variation) < 300:
            raise ValueError(f'The mesh silhouette did not animate on {side}')
        after = args.run / side / 'after-key.png'
        _, remaining = sample(after)
        if remaining:
            raise ValueError(f'The mesh was not removed by the keypress on {side}')
        results[side] = dict(samples=reports, silhouette_changes=variation,
                             cleared_after_key_sha256=sha(after.read_bytes()))
    print(json.dumps(dict(result='pass', source_sha256=capture['source_sha256'],
                          input_sha256=capture['input_sha256'], runs=results), indent=2))


if __name__ == '__main__':
    main()
