"""Capture the bundled raw-disk read and its two class reports."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

from PIL import Image, ImageOps


SOURCE = Path('Demo/Dsk/DskRaw.HC')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture(guest_type, disk, output, native):
    guest = guest_type(disk, output, native, reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        drive = 'C' if native else 'T'
        if not native:
            guest.type('WinMax;Cd("B:/");')
            guest.press('ret')
            time.sleep(1)
        start = len(guest.collect())
        guest.type(f'ExeFile("{drive}:/{SOURCE}");')
        guest.press('ret')
        vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
        font = vision['glyphs'](Path('Kernel/FontStd.HC'))
        frames = {
            'drive-summary': 'PRESS A KEY',
            'drive-class': 'Class:"CDrv"',
            'device-class': 'Class:"CBlkDev"',
            'sector-prompt': 'Blk to Read:',
        }
        for index, (frame, phrase) in enumerate(frames.items()):
            if index:
                guest.press('spc')
            deadline = time.monotonic()+40
            while time.monotonic() < deadline:
                if native:
                    log = guest.collect()[start:]
                    if 'INPUT REJECT ' in log:
                        raise ValueError(log[-2000:])
                guest.screenshot(frame)
                path = output / f'{frame}.png'
                inverse = output / 'inverted.png'
                with Image.open(path) as image:
                    ImageOps.invert(image.convert('RGB')).save(inverse)
                if any(vision['matches'](candidate, phrase, font, first_row=0)
                       for candidate in (path, inverse)):
                    break
                time.sleep(.5)
            else:
                raise TimeoutError(f'{frame} never rendered {phrase!r}')
        guest.press('0')
        guest.press('ret')
        if native:
            guest.wait('COMMAND OK\n', timeout=25, start=start)
        # Keep the physical pointer clear of the hexadecimal columns.
        for _ in range(8):
            guest.call('input-send-event', events=[
                {'type': 'rel', 'data': {'axis': 'x', 'value': 100}},
            ])
            time.sleep(.12)
        time.sleep(1)
        guest.screenshot('sector-dump')
        frames['sector-dump'] = None
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
