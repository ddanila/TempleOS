"""Verify matched animation phases using the moon's left edge as the phase."""
import argparse
import json
from pathlib import Path
import runpy

from PIL import Image


def phases(capture, run, side, helpers):
    observations = {}
    for record in run['frames']:
        path = capture / side / record['frame']
        if helpers['sha'](path) != record['sha256']:
            raise ValueError(f'Frame changed on {side}')
        sun, moon = helpers['colors'](path)
        left = min(x for x, _ in moon)
        if observations and left >= next(reversed(observations)):
            raise ValueError(f'Moon failed to move left on {side}')
        with Image.open(path) as image:
            pixels = image.convert('RGB').load()
            observations[left] = {(x, y): pixels[x, y] for x, y in sun | moon}
    after = capture / side / 'after-animation.png'
    if helpers['sha'](after) != run['after_sha256'] or len(helpers['colors'](after)[0]) >= 200:
        raise ValueError(f'Sun failed to clear on {side}')
    return observations


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    helpers = runpy.run_path(str(Path(__file__).with_name('run.py')))
    receipt = json.loads((args.run / 'result.json').read_bytes())
    if receipt['result'] != 'pass' or not receipt['inputs_unchanged']:
        raise ValueError('Both guests must finish the animation')
    original, native = (phases(args.run, receipt['runs'][side], side, helpers)
                        for side in ('original', 'native'))
    shared = original.keys() & native.keys()
    if len(shared) < 2 or any(original[x] != native[x] for x in shared):
        raise ValueError('At least two shared animation phases must match exactly')
    print(json.dumps(dict(result='pass', input_sha256=receipt['input_sha256'],
                          source_sha256=receipt['source_sha256'],
                          original_left_edges=list(original), native_left_edges=list(native),
                          matching_phase_pixels={x: len(original[x]) for x in sorted(shared)},
                          fresh_result=receipt['runs']['native']['fresh_result']), indent=2))


if __name__ == '__main__':
    main()
