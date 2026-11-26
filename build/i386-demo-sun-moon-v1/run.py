"""Compare the unchanged SunMoon animation and its automatic cleanup."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

from PIL import Image


SOURCE = '/Demo/Graphics/SunMoon.HC'
SUN = {(168, 0, 0), (255, 255, 87)}
MOON = {(168, 168, 168), (87, 87, 87)}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def colors(path):
    with Image.open(path) as image:
        pixels = image.convert('RGB').load()
        sun = {(x, y) for y in range(130, 350) for x in range(25, 232) if pixels[x, y] in SUN}
        moon = {(x, y) for y in range(160, 320) for x in range(355, 600) if pixels[x, y] in MOON}
        return sun, moon


def capture(guest_type, disk, out, native):
    guest = guest_type(disk, out, native, reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        drive = 'C' if native else 'T'
        start = len(guest.collect())
        guest.type(f'Seed(1);ExeFile("{drive}:{SOURCE}");')
        guest.press('ret')
        deadline = time.monotonic() + 90
        frames = []
        previous = set()
        settled = 0
        while time.monotonic() < deadline:
            log = guest.collect()[start:]
            if 'INPUT REJECT ' in log:
                raise ValueError(log[-1500:])
            guest.screenshot('sample')
            path = out / 'sample.png'
            sun, moon = colors(path)
            if len(sun) > 35000 and len(moon) > 180:
                settled = 0
                delta = len(moon ^ previous)
                if delta >= 300 and len(frames) < 4:
                    label = f'animation-{len(frames)}.png'
                    shutil.copyfile(path, out / label)
                    frames.append(dict(frame=label, sha256=sha(path), sun_pixels=len(sun),
                                       moon_pixels=len(moon), moon_change=delta))
                    previous = moon
            elif len(sun) < 200 and frames:
                settled += 1
                if settled >= 3 and (not native or 'COMMAND OK\n' in log):
                    shutil.copyfile(path, out / 'after-animation.png')
                    break
            time.sleep(.08)
        else:
            raise TimeoutError(f'SunMoon did not settle after animation on {out.name}')
        if len(frames) < 3:
            raise ValueError(f'Fewer than three distinct moon frames on {out.name}')
        result = dict(frames=frames, after_sha256=sha(out / 'after-animation.png'))
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
