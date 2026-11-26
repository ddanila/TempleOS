"""Read the callback tags from VGA pixels and check their lifetimes."""
import argparse
import json
from pathlib import Path
import re
import runpy

from PIL import Image


CONSOLE = re.compile(r'\d{2}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}')
BORDER = re.compile(r'\d+=\d{2}:\d{2}:\d{2}')


def tags(frame, glyphs):
    with Image.open(frame) as image:
        pixels = image.convert('RGB').load()
        results = {}
        for name, pattern, color in (
            ('console', CONSOLE, (255, 87, 87)),
            ('border', BORDER, (168, 0, 0)),
        ):
            hits = []
            for top in range(8, image.height - 7, 8):
                cells = []
                for left in range(0, image.width - 7, 8):
                    glyph = tuple(sum(1 << x for x in range(8)
                                      if pixels[left + x, top + y] == color)
                                  for y in range(8))
                    cells.append(glyphs.get(glyph, '?'))
                hits.extend(pattern.findall(''.join(cells)))
            results[name] = hits
        return results


def clock_seconds(text):
    hours, minutes, seconds = map(int, text[-8:].split(':'))
    return hours * 3600 + minutes * 60 + seconds


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('comparison', type=Path)
    args = parser.parse_args()
    runner = runpy.run_path(str(Path(__file__).with_name('run.py')))
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = Path('Kernel/FontStd.HC')
    table = vision['glyphs'](font)
    glyphs = {table[ord(character)]: character for character in '0123456789 /=:'}
    receipt = json.loads((args.comparison / 'result.json').read_bytes())
    if not receipt['inputs_unchanged']:
        raise ValueError('Input changed during capture')
    runs = {}
    mismatches = []
    for side, record in receipt['runs'].items():
        if record['result'] != 'captured':
            raise ValueError(f'{side} did not capture the complete workflow')
        frames = {}
        for name, digest in record['screenshots_sha256'].items():
            frame = args.comparison / side / f'{name}.png'
            if runner['sha'](frame) != digest:
                raise ValueError(f'{side} frame changed: {name}')
            frames[name] = tags(frame, glyphs)

        for name in ('console', 'border'):
            first, second, undo = (frames[frame][name] for frame in
                                   ('clock-first', 'clock-second', 'undo'))
            if len(first) != 1 or len(second) != 1:
                raise ValueError(f'{side} missing or ambiguous {name} tag: {frames}')
            if not 0 < (clock_seconds(second[0]) - clock_seconds(first[0])) % 86400 <= 15:
                raise ValueError(f'{side} {name} clock did not advance: {frames}')
            if name == 'border':
                if undo or int(second[0].split('=')[0]) <= int(first[0].split('=')[0]):
                    raise ValueError(f'{side} border timer or UndoIt failed: {frames}')
            elif len(undo) != 1:
                mismatches.append(f'{side} console tag did not survive UndoIt')
            elif not 0 < (clock_seconds(undo[0]) - clock_seconds(second[0])) % 86400 <= 15:
                mismatches.append(f'{side} console tag stopped advancing after UndoIt')
        runs[side] = frames
    report = dict(result='fail' if mismatches else 'pass',
                  font_sha256=runner['sha'](font), runs=runs,
                  fresh_result=receipt['runs']['native']['fresh_result'],
                  mismatches=mismatches)
    print(json.dumps(report, indent=2))
    if mismatches:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
