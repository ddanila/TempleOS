"""Exercise both animated point clouds and compare the printed random sequences."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import re
import runpy
import shutil
import time

from PIL import Image


SOURCE = Path('Demo/RandDemo.HC')
PALETTE = {(r, g, b) for r in (0, 168) for g in (0, 168) for b in (0, 168)} - {(0, 0, 0)}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sequences(frame, glyphs):
    with Image.open(frame) as image:
        pixels = image.convert('RGB').load()
        lookup = {glyphs[c]: chr(c) for c in b'0123456789-: '}
        values = []
        for row in range(image.height // 8):
            chars = []
            for col in range(14):
                mask = tuple(sum((pixels[col*8+x, row*8+y] != (255,255,255)) << x
                                 for x in range(8)) for y in range(8))
                chars.append(lookup.get(mask, '?'))
            digits = re.search(r'([0-4]): (-?\d+) ', ''.join(chars))
            if digits:
                values.append((int(digits[1]), int(digits[2])))
    if [i for i, _ in values] != list(range(5)) * 5:
        raise ValueError(f'Expected five complete printed sequences: {values}')
    return [[v for _, v in values[offset:offset+5]] for offset in range(0, 25, 5)]


def wait_prompt(guest, text, name, vision, font, start):
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        log = guest.collect()[start:]
        if 'INPUT REJECT ' in log:
            raise ValueError(log[-1800:])
        guest.screenshot(name)
        if vision['matches'](guest.out / f'{name}.png', text, font):
            return
        time.sleep(.3)
    raise TimeoutError(f'Missing {name} in {guest.out.name}')


def capture(guest_type, vision, font, image, out, native):
    guest = guest_type(image, out, native, reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        drive = 'C' if native else 'T'
        start = len(guest.collect())
        guest.type(f'ExeFile("{drive}:/{SOURCE}");')
        guest.press('ret')
        cloud_counts = []
        for label, text in (('timer', 'will do timer XORed'), ('fixed', 'will do deterministic')):
            wait_prompt(guest, text, label, vision, font, start)
            guest.press('spc')
            time.sleep(.3)
            frame = out / f'{label}-cloud.png'
            guest.screenshot(f'{label}-cloud')
            with Image.open(frame) as image:
                colors = image.convert('RGB').crop((24, 180, 296, 460)).getcolors(100000)
                cloud_counts.append(sum(count for count, color in colors if color in PALETTE))
        if native:
            guest.wait('COMMAND OK\n', start=start)
        time.sleep(3)
        guest.screenshot('completed')
        frame = out / 'completed.png'
        values = sequences(frame, font)
        if values[0] != values[2] or values[0] == values[1] or values[3] == values[4]:
            raise ValueError('Repeated, distinct, or timing-seeded behavior differs')
        if min(cloud_counts) < 100:
            raise ValueError(f'Insufficient colored points: {cloud_counts}')
        report = dict(result='pass', printed=values, cloud_pixels=cloud_counts,
                      screenshots_sha256={name:sha(out / f'{name}.png')
                                          for name in ('timer-cloud','fixed-cloud','completed')})
        if native:
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
    original, native = (p.resolve() for p in (args.original_iso, args.native_image))
    pins = {str(p): sha(p) for p in (original, native, SOURCE.resolve())}
    disk = out / 'working.img'
    shutil.copyfile(native, disk)
    guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = vision['glyphs'](Path('Kernel/FontStd.HC'))
    runs = {}
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = {name: pool.submit(capture, guest, vision, font, image, out / name, name == 'native')
                   for name, image in (('original', original), ('native', disk))}
        for side, future in futures.items():
            try:
                runs[side] = future.result()
            except (TimeoutError, RuntimeError, ValueError) as error:
                runs[side] = dict(result='fail', error=str(error))
    unchanged = all(sha(Path(p)) == pin for p, pin in pins.items())
    passed = unchanged and all(result['result']=='pass' for result in runs.values())
    if passed:
        passed = runs['original']['printed'][:3] == runs['native']['printed'][:3]
    report = dict(result='pass' if passed else 'fail', input_sha256=pins,
                  inputs_unchanged=unchanged, runs=runs)
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if not passed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
