"""Capture a bundled graphics demo before and after its keypress."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture(guest_type, image, out, native, source):
    guest = guest_type(image, out, native, reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        guest.type(f'ExeFile("{drive}:{source}");')
        guest.press('ret')
        time.sleep(7)
        guest.screenshot('before-key')
        guest.press('spc')
        if native:
            guest.wait('COMMAND OK\n', timeout=20, start=start)
            command_log = guest.collect()[start:]
            if 'INPUT REJECT ' in command_log:
                raise ValueError(command_log[-1000:])
        time.sleep(2)
        guest.screenshot('after-key')
        if native:
            guest.command('6*7;')
            guest.result_pixels()
    finally:
        guest.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original_iso', type=Path)
    parser.add_argument('native_image', type=Path)
    parser.add_argument('--demo', choices=('SpritePlot', 'Extents'), default='SpritePlot')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    original, native = (path.resolve() for path in (args.original_iso, args.native_image))
    out = args.out.resolve()
    out.mkdir()
    disk = out / 'working.img'
    shutil.copyfile(native, disk)
    pins = {str(path): sha(path) for path in (original, native)}
    source = f'/Demo/Graphics/{args.demo}.HC'
    guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    report = dict(result='captured', input_sha256=pins, source_sha256=sha(Path(source[1:])))
    try:
        with ThreadPoolExecutor(max_workers=2) as pool:
            reference = pool.submit(capture, guest, original, out / 'original', False, source)
            target = pool.submit(capture, guest, disk, out / 'native', True, source)
            reference.result()
            target.result()
    except (RuntimeError, ValueError, TimeoutError) as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(path)) == digest for path, digest in pins.items())
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
