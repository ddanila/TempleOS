"""Verify both guests draw identical seeded traces outside the desktop icon."""
import argparse
import json
from pathlib import Path
import runpy


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    runner = runpy.run_path(str(Path(__file__).with_name('run.py')))
    receipt = json.loads((args.run / 'result.json').read_bytes())
    if receipt['result'] != 'pass' or not receipt['inputs_unchanged']:
        raise ValueError('Both guests must complete the unchanged workflow')
    pins = {}
    for name, color in runner['STAGES'].items():
        masks = []
        for side in ('original', 'native'):
            image = args.run / side / f'{name}.png'
            expected = receipt['runs'][side]['traces'][name]['screenshot_sha256']
            if runner['sha'](image) != expected:
                raise ValueError(f'Frame changed for {side} {name}')
            masks.append(runner['mask'](image, color))
        if name == 'discrete':
            # The original desktop icon is above the curve in this rectangle.
            masks = [{(x, y) for x, y in pixels if not (400 <= x < 425 and 95 <= y < 120)}
                     for pixels in masks]
        if not masks[0] or masks[0] != masks[1]:
            raise ValueError(f'{name} trace differs by {len(masks[0] ^ masks[1])} pixels')
        pins[name] = len(masks[0])
    print(json.dumps(dict(result='pass', input_sha256=receipt['input_sha256'],
                          source_sha256=receipt['source_sha256'], matching_pixels=pins), indent=2))


if __name__ == '__main__':
    main()
