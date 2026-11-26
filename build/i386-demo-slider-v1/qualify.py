"""Verify slider knob positions, printed values and i386 prompt recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

from PIL import Image


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def yellow(rgb):
    return rgb[0] > 190 and rgb[1] > 190 and rgb[2] < 130


def knobs(path, origin):
    x, y = origin
    with Image.open(path) as frame:
        pixels = frame.convert('RGB').load()
        centers = []
        for offset in (20, 41):
            rows = {
                dy: sum(yellow(pixels[x + offset + dx, y + dy]) for dx in range(-2, 3))
                for dy in range(18, 53)
            }
            # The physical cursor can cover some pixels in the 5-by-3 knob.
            scores = {dy: rows[dy - 1] + rows[dy] + rows[dy + 1]
                      for dy in range(19, 52)}
            strongest = max(scores.values())
            candidates = [dy for dy, score in scores.items() if score == strongest]
            if strongest < 8 or candidates[-1] - candidates[0] > 2:
                raise ValueError(f'Missing slider knob in {path} at x={x + offset}')
            centers.append((candidates[0] + candidates[-1]) / 2)
        return centers


def verify(run):
    result = json.loads((run / 'result.json').read_text())
    if result['result'] != 'pass' or not result['inputs_unchanged']:
        raise ValueError('The original and native guests must both finish')
    for filename, expected in result['input_sha256'].items():
        if sha(Path(filename)) != expected:
            raise ValueError(f'Input changed: {filename}')
    observed = {}
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = vision['glyphs'](Path('Kernel/FontStd.HC'))
    for side, guest in result['runs'].items():
        directory = run / side
        frames = ('slider', 'click-1', 'click-2')
        centers = [knobs(directory / f'{frame}.png', guest['origin']) for frame in frames]
        targets = ((49, 49), (24, 49), (24, 33))
        if any(abs(got - want) > 2 for pair, target in zip(centers, targets)
               for got, want in zip(pair, target)):
            raise ValueError(f'Unexpected knob positions for {side}: {centers}')
        output = directory / 'output.png'
        locations = vision['matches'](output, 'Left: 8  Right: 5', font, first_row=0)
        if not locations:
            raise ValueError(f'Missing slider output on {side}')
        observed[side] = dict(knob_centers=centers, output_locations=locations,
                              captures={name:sha(directory / f'{name}.png')
                                        for name in (*frames, 'output')})
    native_output = run / 'native' / 'executed.png'
    verifier = runpy.run_path('tools/test-i386-autocomplete-interaction.py')
    match = verifier['has_result_pixels'](native_output)
    if not match or match != result['runs']['native']['fresh_arithmetic']:
        raise ValueError('Missing native arithmetic result after demo exit')
    observed['native']['fresh_arithmetic'] = dict(match=match, sha256=sha(native_output))
    return dict(result='pass', capture_receipt_sha256=sha(run / 'result.json'),
                observations=observed)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    print(json.dumps(verify(args.run), indent=2))


if __name__ == '__main__':
    main()
