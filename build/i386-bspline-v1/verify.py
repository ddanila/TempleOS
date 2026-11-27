"""Compare closed spline rasterization from paired physical-input guest runs."""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageFilter


COLORS = {'green': (0, 168, 0), 'red': (168, 0, 0), 'blue': (0, 0, 168)}
CANVAS = (25, 90, 306, 390)


def color_mask(directory, color):
    with Image.open(directory / 'guest' / 'curves.png') as frame:
        canvas = frame.convert('RGB').crop(CANVAS)
    mask = Image.new('L', canvas.size)
    mask.putdata([255 if pixel == color else 0 for pixel in canvas.get_flattened_data()])
    return mask


def near_pixels(mask, other, radius):
    neighborhood = other.filter(ImageFilter.MaxFilter(2 * radius + 1)) if radius else other
    return sum(a and bool(b) for a, b in zip(
        mask.get_flattened_data(), neighborhood.get_flattened_data()))


def compare(reference, native):
    original = json.loads((reference / 'result.json').read_text())
    port = json.loads((native / 'result.json').read_text())
    assert original['result'] == port['result'] == 'pass'
    assert original['demo_sha256'] == port['demo_sha256']
    assert len(original['points']) == len(port['points']) == 6
    deviation = max(abs(a - b) for pair in zip(original['points'], port['points'])
                    for a, b in zip(*pair))
    assert deviation <= 4
    # Paired pointer positions can differ by up to four pixels per axis.
    radius = deviation
    results = {}
    for name, rgb in COLORS.items():
        reference_mask = color_mask(reference, rgb)
        native_mask = color_mask(native, rgb)
        reference_size = reference_mask.histogram()[255]
        native_size = native_mask.histogram()[255]
        assert reference_size > 0 and native_size > 0, name
        assert abs(reference_size - native_size) <= reference_size * .08, name
        reference_near = near_pixels(reference_mask, native_mask, radius)
        native_near = near_pixels(native_mask, reference_mask, radius)
        assert reference_near >= reference_size * .97, name
        assert native_near >= native_size * .97, name
        if deviation == 0:
            assert reference_mask.tobytes() == native_mask.tobytes(), name
        results[name] = dict(reference_pixels=reference_size, native_pixels=native_size,
                             reference_near_native=reference_near,
                             native_near_reference=native_near)
    return dict(result='pass', demo_sha256=original['demo_sha256'],
                points_max_axis_delta=deviation, matching_radius=radius, colors=results)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('reference', type=Path)
    parser.add_argument('native', type=Path)
    args = parser.parse_args()
    print(json.dumps(compare(args.reference, args.native), indent=2))
