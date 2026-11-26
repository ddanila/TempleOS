"""Exercise inferred class names and both reports in the bundled LastClass demo."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time


SOURCE = Path('Demo/LastClass.HC')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture(guest_type, disk, output, native):
    guest = guest_type(disk, output, native, reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        drive = 'C' if native else 'T'
        start = len(guest.collect())
        guest.type(f'ExeFile("{drive}:/{SOURCE}");')
        guest.press('ret')
        vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
        font = vision['glyphs'](Path('Kernel/FontStd.HC'))
        frames = {
            'inferred-classes': 'is a "School".',
            'live-report': 'Class:"CCPU"',
            'static-report': 'user_data',
        }
        for index, (frame, phrase) in enumerate(frames.items()):
            if index:
                guest.press('spc')
            if native and index == 2:
                guest.wait('COMMAND OK\n', timeout=25, start=start)
            deadline = time.monotonic()+40
            while time.monotonic() < deadline:
                if native:
                    log = guest.collect()[start:]
                    if 'INPUT REJECT ' in log:
                        raise ValueError(log[-2000:])
                guest.screenshot(frame)
                if vision['matches'](output / f'{frame}.png', phrase, font, first_row=0):
                    break
                time.sleep(.5)
            else:
                raise ValueError(f'{frame} never rendered {phrase!r}')
        screenshots = {frame: sha(output / f'{frame}.png') for frame in frames}
        result = dict(result='captured', screenshots_sha256=screenshots)
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
    original = args.original_iso.resolve()
    native = args.native_image.resolve()
    pins = {str(path): sha(path) for path in (original, native, SOURCE.resolve())}
    disk = out / 'working.img'
    shutil.copyfile(native, disk)
    guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    runs = {}
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = {side: pool.submit(capture, guest, image, out / side, side == 'native')
                   for side, image in (('original', original), ('native', disk))}
        for side, future in futures.items():
            try:
                runs[side] = future.result()
            except (RuntimeError, TimeoutError, ValueError) as error:
                runs[side] = dict(result='fail', error=str(error))
    unchanged = all(sha(Path(path)) == digest for path, digest in pins.items())
    report = dict(input_sha256=pins, inputs_unchanged=unchanged, runs=runs)
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
