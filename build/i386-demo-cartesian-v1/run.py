"""Compare the unchanged Cartesian demo's equation input, plotted slope and Escape exit."""
import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

from PIL import Image


SOURCE = '/Demo/Graphics/Cartesian.HC'
RED = (168, 0, 0)
BLACK = (0, 0, 0)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def axes(pixels, search_width):
    rows = Counter(y for x, y in pixels)
    columns = Counter(x for x, y in pixels)
    if rows and columns:
        y, width = rows.most_common(1)[0]
        x, height = columns.most_common(1)[0]
        if width >= 160 and height >= 100 and 60 <= x < search_width - 60:
            return x, y


def inspect(frame, search_width):
    with Image.open(frame) as image:
        pixels = image.convert('RGB').load()
        red = {(x, y) for x in range(search_width) for y in range(32, 448)
               if pixels[x, y] == RED}
        origin = axes(red, search_width)
        if origin is None:
            return
        x, y = origin
        rising = 0
        falling = 0
        for dx in (*range(-60, -12), *range(12, 60)):
            rising += any(pixels[x+dx, y-dx//2+dy] == BLACK for dy in (-1, 0, 1))
            falling += any(pixels[x+dx, y+dx//2+dy] == BLACK for dy in (-1, 0, 1))
        return dict(origin=origin, rising_samples=rising, falling_samples=falling)


def graph(guest, label, width, slope, start):
    deadline = time.monotonic() + 90
    path = guest.out / f'{label}.png'
    while time.monotonic() < deadline:
        log = guest.collect()[start:]
        if 'INPUT REJECT ' in log:
            raise ValueError(log[-1800:])
        guest.screenshot(label)
        result = inspect(path, width)
        opposite = 'falling' if slope == 'rising' else 'rising'
        if result and result[f'{slope}_samples'] >= 70 and result[f'{opposite}_samples'] <= 20:
            result['screenshot_sha256'] = sha(path)
            return result
        time.sleep(1)
    raise ValueError(f'{label} did not display the expected slope on {guest.out.name}')


def capture(guest_type, disk, out, native):
    guest = guest_type(disk, out, native, reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        width = 640 if native else 320
        guest.type(f'ExeFile("{drive}:{SOURCE}");')
        guest.press('ret')
        time.sleep(3)
        guest.screenshot('equation-prompt')
        guest.type('x/2')
        guest.press('ret')
        rising = graph(guest, 'rising', width, 'rising', start)
        guest.press('spc')
        time.sleep(2)
        guest.type('-x/2')
        guest.press('ret')
        falling = graph(guest, 'falling', width, 'falling', start)
        guest.press('esc')
        if native:
            guest.wait('COMMAND OK\n', start=start)
            if 'INPUT REJECT ' in guest.collect()[start:]:
                raise ValueError(guest.collect()[start:][-1800:])
        time.sleep(2)
        guest.screenshot('after-escape')
        path = out / 'after-escape.png'
        if inspect(path, width):
            raise ValueError(f'Graph remained after Escape on {out.name}')
        result = dict(rising=rising, falling=falling, after_escape_sha256=sha(path))
        if native:
            guest.command('6*7;')
            result['fresh_result'] = guest.result_pixels()
        return result
    finally:
        guest.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original_iso', type=Path)
    parser.add_argument('native_image', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    original, native = (path.resolve() for path in (args.original_iso, args.native_image))
    inputs = {str(path): sha(path) for path in (original, native)}
    disk = out / 'working.img'
    shutil.copyfile(native, disk)
    guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    report = dict(input_sha256=inputs, source_sha256=sha(Path(SOURCE[1:])), runs={})
    with ThreadPoolExecutor(max_workers=2) as pool:
        runs = {side: pool.submit(capture, guest_type, image, out / side, side == 'native')
                for side, image in (('original', original), ('native', disk))}
        for side, future in runs.items():
            try:
                report['runs'][side] = {'result': 'pass', **future.result()}
            except (RuntimeError, TimeoutError, ValueError) as ex:
                report['runs'][side] = dict(result='fail', error=str(ex))
    report['inputs_unchanged'] = all(sha(Path(path)) == digest for path, digest in inputs.items())
    passed = report['inputs_unchanged'] and all(run['result'] == 'pass' for run in report['runs'].values())
    report['result'] = 'pass' if passed else 'fail'
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if not passed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
