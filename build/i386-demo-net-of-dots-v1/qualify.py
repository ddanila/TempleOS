"""Compare the NetOfDots raster in the portion visible in both guest windows."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

from PIL import Image


SOURCE = Path('Demo/Graphics/NetOfDots.HC')
RED = (168, 0, 0)
DOMAIN = (8, 16, 300, 440)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def red_mask(path, origin):
    x0, y0 = origin
    left, top, right, bottom = DOMAIN
    with Image.open(path) as image:
        pixels = image.convert('RGB').load()
        return {(x, y) for y in range(top, bottom) for x in range(left, right)
                if pixels[x0+x, y0+y] == RED}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    result = json.loads((args.run / 'result.json').read_bytes())
    if (result['result'] != 'captured' or not result['inputs_unchanged']
            or result['source_sha256'] != sha(SOURCE)):
        raise ValueError('Both guests must complete the unchanged demo')
    masks = {}
    evidence = {}
    for side, origin in (('original', (8, 16)), ('native', (0, 0))):
        before, after = (args.run / side / f'{name}.png' for name in ('before-key', 'after-key'))
        masks[side] = red_mask(before, origin)
        if red_mask(after, origin):
            raise ValueError(f'Red pixels remained after Space on {side}')
        evidence[side] = dict(origin=origin, before_sha256=sha(before), after_sha256=sha(after))
    original = masks['original']
    if len(original) < 1000 or original != masks['native']:
        mismatch = len(original ^ masks['native'])
        raise ValueError(f'Red net mismatch: {len(original)} original pixels, {mismatch} differing pixels')
    executed = args.run / 'native/executed.png'
    has_result = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['has_result_pixels']
    fresh = has_result(executed)
    if not fresh:
        raise ValueError('The native prompt did not evaluate the fresh command')
    report = dict(result='pass', source_sha256=result['source_sha256'],
                  input_sha256=result['input_sha256'], window_relative_crop=DOMAIN,
                  matching_red_pixels=len(original), frames=evidence, fresh_result=fresh,
                  executed_sha256=sha(executed))
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
