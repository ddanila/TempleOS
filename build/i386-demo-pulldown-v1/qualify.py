"""Verify the saved VGA captures for the bundled pull-down menu workflow."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

from PIL import Image, ImageOps


CONSOLE_FRAMES = {
    'ready': 'A pull-down menu',
    'option-1': 'Option # 1',
    'option-2': 'Option # 2',
    'help': 'Test the menu.',
    'about': 'About PullDown Demo',
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def menu_palette(path, font, item):
    with Image.open(path) as image:
        pixels = image.convert('RGB').load()
        colors = (set(), set())
        for col, letter in enumerate(f'Opt{item}'.encode('ascii')):
            for y, mask in enumerate(font[letter]):
                for x in range(8):
                    colors[bool(mask & (1 << x))].add(
                        pixels[88 + col * 8 + x, (item + 1) * 8 + y])
    if any(len(group) != 1 for group in colors) or colors[0] == colors[1]:
        raise ValueError(f'Missing intact Opt{item} label in {path}')
    return [next(iter(group)) for group in colors]


def verify(run, source, temporary):
    receipt = json.loads((run / 'result.json').read_text())
    pins = receipt['input_sha256']
    source_hash = digest(source)
    if not receipt['inputs_unchanged'] or pins.get(str(source.resolve())) != source_hash:
        raise ValueError('Input image or demo source identity changed')
    for name, expected in pins.items():
        if digest(Path(name)) != expected:
            raise ValueError(f'Pinned input changed: {name}')
    native_checks = runpy.run_path('tools/test-i386-autocomplete-interaction.py')
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font_path = Path('Kernel/FontStd.HC')
    font = vision['glyphs'](font_path)
    result = {}
    for side in ('original', 'native'):
        guest = receipt['runs'][side]
        if guest['result'] != 'captured':
            raise ValueError(f'{side} did not finish: {guest}')
        directory = run / side
        observations = {}
        for frame, phrase in CONSOLE_FRAMES.items():
            path = directory / f'{frame}.png'
            with Image.open(path) as image:
                ImageOps.invert(image.convert('RGB')).save(temporary)
            rows = vision['matches'](path, phrase, font, first_row=0)
            rows += vision['matches'](temporary, phrase, font, first_row=0)
            if not rows:
                raise ValueError(f'{phrase!r} is absent from {path}')
            observations[frame] = rows
        for item in (1, 2):
            before, selected = [
                menu_palette(directory / f'{frame}-{item}.png', font, item)
                for frame in ('menu', 'highlight')
            ]
            if before == selected:
                raise ValueError(f'Opt{item} selection is absent on {side}')
            observations[f'Opt{item}'] = dict(before=before, selected=selected)
        for frame, expected in guest['frames_sha256'].items():
            if digest(directory / f'{frame}.png') != expected:
                raise ValueError(f'Capture changed on {side}: {frame}')
        result[side] = observations
    native = run / 'native' / 'executed.png'
    fresh = native_checks['has_result_pixels'](native)
    if not fresh or json.loads(json.dumps(fresh)) != receipt['runs']['native']['fresh_result']:
        raise ValueError('Native prompt recovery capture is missing or different')
    result['native']['fresh_arithmetic'] = dict(match=fresh, sha256=digest(native))
    return dict(result='pass', source_sha256=source_hash, font_sha256=digest(font_path),
                capture_receipt_sha256=digest(run / 'result.json'), observations=result)


def main():
    from tempfile import TemporaryDirectory

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    with TemporaryDirectory() as tmp:
        report = verify(args.run, Path('Demo/PullDownMenu.HC'), Path(tmp) / 'inverse.png')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
