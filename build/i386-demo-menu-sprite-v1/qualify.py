"""Compare the rendered heart and verify the recorded speaker measurements."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

from PIL import Image


def red_pixels(path):
    with Image.open(path) as image:
        pixels = image.convert('RGB').load()
        return {(x, y) for y in range(8, 48) for x in range(40, 80)
                if pixels[x, y] == (168, 0, 0)}


def normalize(points):
    left = min(x for x, _ in points)
    top = min(y for _, y in points)
    return sorted((x - left, y - top) for x, y in points)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    receipt = json.loads((args.run / 'result.json').read_bytes())
    if receipt['result'] != 'pass' or not receipt['inputs_unchanged']:
        raise ValueError('Both guests must pass the keyboard and speaker workflow')

    runner = runpy.run_path(str(Path(__file__).with_name('run.py')))
    hearts = {}
    for side, result in receipt['runs'].items():
        output = args.run / side
        for panel, digest in result['screenshots_sha256'].items():
            frame = output / f'{panel}.png'
            if runner['sha'](frame) != digest:
                raise ValueError(f'{side} frame changed: {panel}')
            pixels = red_pixels(frame)
            if panel == 'after-exit':
                if pixels:
                    raise ValueError(f'{side} still renders red pixels in the heart area')
            else:
                heart = normalize(pixels)
                if len(heart) != 201 or hearts.setdefault(side, heart) != heart:
                    raise ValueError(f'{side} heart mask changed: {panel}')

        audio = output / 'speaker.wav'
        measured = {str(hz): count for hz, count in runner['frequencies'](audio).items()}
        if runner['sha'](audio) != result['audio_sha256'] or measured != result['tone_windows']:
            raise ValueError(f'{side} audio changed')
    if hearts['native'] != hearts['original']:
        raise ValueError('The native heart differs from the original')
    heart_sha256 = hashlib.sha256(json.dumps(hearts['native']).encode()).hexdigest()
    print(json.dumps(dict(result='pass', heart_pixels=len(hearts['native']),
                          heart_sha256=heart_sha256,
                          comparison_sha256=runner['sha'](args.run / 'result.json')), indent=2))


if __name__ == '__main__':
    main()
