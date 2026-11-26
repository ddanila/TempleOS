"""Exercise the five keyboard-stepped traces in the original LowPassFilter demo."""
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


DEMO = '/Demo/Graphics/LowPassFilter.HC'
STAGES = {
    'step': (0, 0, 168),
    'continuous': (0, 168, 168),
    'discrete': (0, 0, 0),
    'random-slow': (168, 0, 0),
    'random-fast': (0, 168, 0),
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def mask(path, color):
    with Image.open(path) as image:
        pixels = image.convert('RGB').load()
        return {(x, y) for y in range(32, 430) for x in range(16, 624)
                if pixels[x, y] == color}


def observe(guest, stage, color, start):
    frame = guest.out / f'{stage}.png'
    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        output = guest.collect()[start:]
        if 'INPUT REJECT ' in output:
            raise ValueError(output[-1500:])
        guest.screenshot(stage)
        points = mask(frame, color)
        row_span = max(Counter(y for _, y in points).values(), default=0)
        if len(points) > 160 and (stage != 'step' or row_span >= 260):
            return dict(pixels=len(points), widest_row=row_span, screenshot_sha256=sha(frame))
        time.sleep(1)
    raise TimeoutError(f'The {stage} trace was not visible on {guest.out.name}')


def capture(guest_type, disk, out, native):
    guest = guest_type(disk, out, native, reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        guest.type(f'Seed(1);ExeFile("{drive}:{DEMO}");')
        guest.press('ret')
        traces = {}
        for stage, color in STAGES.items():
            traces[stage] = observe(guest, stage, color, start)
            guest.press('spc')
            time.sleep(1)
        guest.screenshot('after-space')
        frame = out / 'after-space.png'
        if any(len(mask(frame, STAGES[stage])) > 160 for stage in ('continuous', 'random-slow', 'random-fast')):
            raise ValueError(f'The filter traces remained on {out.name}')
        report = dict(traces=traces, after_space_sha256=sha(frame))
        if native:
            guest.wait('COMMAND OK\n', start=start)
            guest.command('6*7;')
            report['fresh_result'] = guest.result_pixels()
        return report
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
    report = dict(input_sha256=inputs, source_sha256=sha(Path(DEMO[1:])), runs={})
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
