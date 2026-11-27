"""Check the paired Stadium game receipts against their captured frames."""
import hashlib
import json
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
DEMO = ROOT / 'Demo/Games/Stadium/Stadium.HC'
BACKGROUND = DEMO.with_name('StadiumBG.GR')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pixels(mode, frame, box):
    path = OUT / mode / (frame + '.png')
    with Image.open(path) as image:
        if image.size != (640, 480):
            raise ValueError(f'Unexpected frame size for {path}')
        return image.convert('RGB').crop(box).get_flattened_data()


def difference(first, second):
    return sum(a != b for a, b in zip(first, second, strict=True))


background_box = (0, 120, 640, 480)
pitch_box = (80, 180, 600, 455)
reports = {}
for mode in ('original', 'native'):
    receipt = json.loads((OUT / (mode + '-result.json')).read_text())
    if (receipt['result'] != 'pass' or receipt['source_sha256'] != sha(DEMO) or
            receipt['background_sha256'] != sha(BACKGROUND) or receipt['title'] != [8, 16]):
        raise ValueError(f'Invalid launch evidence for {mode}')
    fan_box = (0, 36, 640, 126)
    animated = difference(pixels(mode,'fans-before',fan_box), pixels(mode,'fans-after',fan_box))
    restarted = difference(pixels(mode,'fans-after',fan_box), pixels(mode,'restart',fan_box))
    samples = receipt['pitch_region_pixels_changed']
    peak = max(samples)
    peak_frame = 'pitch-' + str(samples.index(peak))
    pitch = pixels(mode,'pitch-before',pitch_box)
    if (animated != receipt['fan_region_pixels_changed'] or animated <= 5 or
            restarted != receipt['restart_fan_region_pixels_changed'] or restarted <= 5 or
            peak < 200 or difference(pitch,pixels(mode,peak_frame,pitch_box)) != peak or
            difference(pitch,pixels(mode,'restart',pitch_box))):
        raise ValueError(f'Frame evidence differs from receipt for {mode}')
    reports[mode] = {'animated_pixels': animated, 'pitch_pixels': peak,
                     'restart_pixels': restarted, 'peak_frame': peak_frame}
    if mode == 'native':
        reports[mode]['fresh_arithmetic'] = receipt['fresh_arithmetic']

background = pixels('original','fans-before',background_box)
if background != pixels('native','fans-before',background_box):
    raise ValueError('Static lower backgrounds differ')
print(json.dumps(dict(result='pass', source_sha256=sha(DEMO), background_sha256=sha(BACKGROUND),
                      matching_background_pixels=len(background), sessions=reports),indent=2))
