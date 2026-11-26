"""Check that the localized prompt is rendered again after invalid input."""
import argparse
import hashlib
import json
from pathlib import Path
import re

from PIL import Image


PROMPTS = ('Exit (Yes or No)?', 'Salida (Si or No)?')


def glyphs(path):
    values = re.findall(rb'0x[0-9A-Fa-f]{16}', path.read_bytes())
    if len(values) != 256:
        raise ValueError('Invalid font size')
    return tuple(tuple(int(bits, 16).to_bytes(8, 'little')) for bits in values)


def matches(path, phrase, font, first_row=1):
    with Image.open(path) as image:
        pixels = image.convert('RGB').load()
        hits = []
        letters = phrase.encode('ascii')
        for row in range(first_row, image.height // 8):
            for col in range(image.width // 8 - len(letters) + 1):
                if all(
                    all((pixels[(col+i)*8+x, row*8+y] != (255, 255, 255)) == bool(mask & (1 << x))
                        for y, mask in enumerate(font[letter]) for x in range(8))
                    for i, letter in enumerate(letters)
                ):
                    hits.append((col, row))
        return hits


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    font_path = Path('Kernel/FontStd.HC')
    font = glyphs(font_path)
    result = json.loads((args.run / 'result.json').read_bytes())
    if result['result'] != 'pass' or not result['inputs_unchanged']:
        raise ValueError('Both guests must finish both locale workflows')
    observations = {}
    for name, run in result['runs'].items():
        prompt = PROMPTS[name.endswith('-spanish')]
        frames = ('localized-prompt', 'retry')
        for frame in frames:
            path = args.run / name / f'{frame}.png'
            if hashlib.sha256(path.read_bytes()).hexdigest() != run['screenshots_sha256'][frame]:
                raise ValueError(f'Frame changed for {name}')
        # The original console can scroll the first character out of view.
        before, after = (matches(args.run / name / f'{frame}.png', prompt[1:], font) for frame in frames)
        if len(before) != 1 or len(after) != 2 or before[0] != after[0]:
            raise ValueError(f'Localized prompt or retry is missing on {name}: {before}, {after}')
        observations[name] = dict(prompt=prompt, initial=before, after_invalid=after)
    report = dict(result='pass', font_sha256=hashlib.sha256(font_path.read_bytes()).hexdigest(),
                  source_sha256=result['source_sha256'], input_sha256=result['input_sha256'],
                  observations=observations)
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
