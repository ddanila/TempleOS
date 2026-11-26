"""Capture CallBack's changing border and console tags before and after UndoIt."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time


SOURCE = Path('Demo/DolDoc/CallBack.HC')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture(guest_type, disk, output, native):
    guest = guest_type(disk, output, native, reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        drive = 'C' if native else 'T'
        for command, frames in (
            (f'ExeFile("{drive}:/{SOURCE}");', ('clock-first', 'clock-second')),
            ('UndoIt;', ('undo',)),
        ):
            start = len(guest.collect())
            guest.type(command)
            guest.press('ret')
            if native:
                log = guest.wait('COMMAND OK\n', timeout=20, start=start)
                if 'INPUT REJECT ' in log[start:]:
                    raise ValueError(log[start:][-2000:])
            time.sleep(2)
            for frame in frames:
                guest.screenshot(frame)
                time.sleep(2)
        result = {'result': 'captured'}
        if native:
            guest.command('6*7;')
            result['fresh_result'] = guest.result_pixels()
        result['screenshots_sha256'] = {
            name: sha(output / f'{name}.png') for name in ('clock-first', 'clock-second', 'undo')
        }
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
