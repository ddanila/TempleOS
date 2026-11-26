"""Check the saved SpritePut records and the rendered flags and map."""
import hashlib
import json
from pathlib import Path
import runpy

from PIL import Image

HERE = Path(__file__).resolve().parent
BATCH = HERE / 'comparison'
DEMO = 'Demo/Graphics/SpritePut.HC'
RED = (168, 0, 0)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def flags(frame):
    with Image.open(frame) as image:
        rgb = image.convert('RGB')
    stripes = []
    for y in range(rgb.height):
        red = [x for x in range(rgb.width) if rgb.getpixel((x, y)) == RED]
        if len(red) >= 80:
            stripes.append((y, min(red), max(red)))
    groups = []
    for stripe in stripes:
        if not groups or stripe[0] - groups[-1][-1][0] > 9:
            groups.append([])
        groups[-1].append(stripe)
    rasters = []
    for group in groups:
        if len(group) < 15:
            continue
        left = min(x for _, x, _ in group)
        right = max(x for _, _, x in group) + 1
        top, bottom = group[0][0], group[-1][0] + 1
        flag = rgb.crop((left, top, right, bottom))
        rasters.append((flag.size, flag.tobytes()))
    return rasters


def main():
    checks = runpy.run_path('build/i386-demo-sprite-ext-v1/qualify.py')
    source = Path(DEMO).read_bytes()
    _, source_bins = checks['bins'](source)
    assets = {number: payload for number, _, _, payload in source_bins}
    expected_text = b''.join(f'US Flag:$SP,"",BI={number}$'.encode('ascii') + b'\n' * 12
                             for number in (1, 2, 3))
    expected_text += b'US Map:$SP,"",BI=4$' + b'\n' * 10 + b'\x05'
    expected_bins = [(number, 0, 1, assets[1 if number < 4 else 2]) for number in range(1, 5)]
    batch = json.loads((BATCH / 'result.json').read_bytes())
    entry = batch['entries'][DEMO]
    if batch['result'] != 'pass' or not batch['inputs_unchanged'] or entry['source_sha256'] != sha(source):
        raise ValueError('The unchanged SpritePut did not complete on both guests')
    seen_flags = {}
    seen_maps = {}
    screenshots = {}
    for side in ('original', 'native'):
        data = (BATCH / side / entry['output_file']).read_bytes()
        if sha(data) != entry[side + '_sha256'] or checks['bins'](data) != (expected_text, expected_bins):
            raise ValueError(f'The four saved sprite records differ on {side}')
        frame = HERE / 'render' / side / 'sprite.png'
        screenshots[side] = sha(frame.read_bytes())
        seen_flags[side] = flags(frame)
        seen_maps[side] = [mask for mask in checks['maps'](frame) if len(mask) >= 1000]
    expected_flags = seen_flags['original']
    if (len(expected_flags) != 3 or expected_flags[0][0] != (143, 83)
            or expected_flags != seen_flags['native']
            or any(flag != expected_flags[0] for flag in expected_flags)):
        raise ValueError('The three flags differ')
    expected_map = seen_maps['original']
    if len(expected_map) != 1 or len(expected_map[0]) != 6300 or expected_map != seen_maps['native']:
        raise ValueError('The map differs')
    print(json.dumps(dict(result='pass', image_sha256=batch['input_sha256'],
                          source_sha256=entry['source_sha256'], document_sha256=entry['native_sha256'],
                          document_bytes=entry['bytes'], flag_count=len(expected_flags),
                          flag_size=expected_flags[0][0], flag_raster_sha256=sha(expected_flags[0][1]),
                          map_pixels=len(expected_map[0]), screenshots_sha256=screenshots), indent=2))


if __name__ == '__main__':
    main()
