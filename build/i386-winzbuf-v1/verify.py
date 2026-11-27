"""Match the unchanged WinZBuf demo to each guest's live window depth map."""
import argparse
import json
from pathlib import Path

from PIL import Image


PALETTE = (
    (0, 0, 0), (0, 0, 168), (0, 168, 0), (0, 168, 168),
    (168, 0, 0), (168, 0, 168), (168, 87, 0), (168, 168, 168),
    (87, 87, 87), (87, 87, 255), (87, 255, 87), (87, 255, 255),
    (255, 87, 87), (255, 87, 255), (255, 255, 87), (255, 255, 255),
)


def crop(path, x, y):
    with Image.open(path) as frame:
        return list(frame.convert('RGB').crop((x, y, x + 80, y + 60)).get_flattened_data())


def verify(directory):
    result = json.loads((directory / 'result.json').read_text())
    assert result['result'] == 'pass'
    maps = []
    observed = []
    for phase, (left, top) in enumerate(((5, 6), (20, 12))):
        state = result[f'phase{phase}']
        assert (state['x'], state['y']) == (left * 8, top * 8)
        indices = [int(color, 16) for color in state['indices']]
        assert len(indices) == 4800
        x, y = state['x'], state['y'] + 8
        expected = [PALETTE[color] for color in indices]
        actual = crop(directory / 'guest' / f'map{phase}.png', x, y)
        assert actual == expected
        depth = indices[(top + 5) * 80 + left + 5]
        region = [indices[row * 80 + col] for row in range(top, top + 32)
                  for col in range(left, left + 39)]
        # Another window may cover part of the rectangle in the original guest.
        assert all(index >= depth for index in region)
        assert region.count(depth) >= 1239
        observed.append(dict(origin=[x, y - 8], matched_pixels=len(actual),
                             window_depth=depth, window_cells=region.count(depth),
                             higher_depth_cells=len(region) - region.count(depth)))
        maps.append(indices)
    # A cell in the original footprint and one in the moved footprint trade depth.
    assert maps[0][8 * 80 + 8] == observed[0]['window_depth'] > maps[1][8 * 80 + 8]
    assert maps[1][40 * 80 + 56] == observed[1]['window_depth'] > maps[0][40 * 80 + 56]
    assert all(PALETTE[color] != pixel for color, pixel in
               zip(maps[1], crop(directory / 'guest' / 'cleared.png', x, y)))
    return result, observed


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path)
    parser.add_argument('native', type=Path)
    args = parser.parse_args()
    original, original_maps = verify(args.original)
    native, native_maps = verify(args.native)
    assert original['demo_sha256'] == native['demo_sha256']
    assert native['fresh_arithmetic']
    print(json.dumps(dict(result='pass', demo_sha256=original['demo_sha256'],
                          original=original_maps, native=native_maps,
                          map_removed_on_exit=True, fresh_arithmetic=native['fresh_arithmetic']),
                     indent=2))
