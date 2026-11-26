"""Compare the bundled Slider demo using actual QEMU mouse clicks."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import re
import runpy
import shutil
import time

from PIL import Image

DEMO = 'Demo/Graphics/Slider.HC'


def wait_for(test, description):
    deadline = time.monotonic() + 45
    while time.monotonic() < deadline:
        result = test()
        if result is not None:
            return result
        time.sleep(.2)
    raise TimeoutError(description)


def slider_origin(frame):
    with Image.open(frame) as image:
        pixels = image.convert('RGB').load()
        for y in range(image.height - 70):
            for x in range(image.width - 62):
                color = pixels[x, y]
                red, green, blue = color
                if red < 190 or green > 130 or blue > 130:
                    continue
                if not all(pixels[x + dx, y] == color for dx in range(62)):
                    continue
                if pixels[x + 62, y] == color or (x and pixels[x - 1, y] == color):
                    continue
                if not all(pixels[x, y + dy] == color for dy in range(70)):
                    continue
                if pixels[x + 10, y + 10][2] <= pixels[x + 10, y + 10][0]:
                    continue
                return x, y
    return None


def capture(Guest, shared, image, out, native):
    guest = Guest(image, out, native, reference_cpus=1)
    observed = {}
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        shared['submit'](guest, shared['POSITION'])
        def address():
            record = re.search(r'^PM POS ([0-9A-F]+)\n', guest.collect(), re.M)
            return int(record.group(1), 16) if record else None
        pointer = wait_for(address, 'Mouse position address was not exported')
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        shared['submit'](guest, f'ExeFile("{drive}:/{DEMO}");')
        def slider():
            log = guest.collect()[start:]
            if 'INPUT REJECT ' in log:
                raise ValueError(log[-1400:])
            guest.screenshot('slider')
            return slider_origin(out / 'slider.png')
        x, y = observed['origin'] = wait_for(slider, 'Slider control was not rendered')
        observed['clicks'] = []
        for index, target in enumerate(((x + 20, y + 24), (x + 41, y + 33)), 1):
            position = shared['move'](guest, pointer, target)
            for down in (True, False):
                guest.call('input-send-event', events=[
                    {'type':'btn', 'data':{'button':'left', 'down':down}}])
                time.sleep(.5)
            guest.screenshot(f'click-{index}')
            observed['clicks'].append(position)
        guest.press('spc')
        vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
        font = vision['glyphs'](Path('Kernel/FontStd.HC'))
        shared['wait_frame'](guest, 'output', 'Left: 8  Right: 5', vision, font, start)
        if native:
            guest.wait('COMMAND OK\n', start=start)
            guest.command('6*7;')
            observed['fresh_arithmetic'] = guest.result_pixels()
        return dict(result='pass', **observed)
    except (RuntimeError, TimeoutError, ValueError) as error:
        return dict(result='fail', error=str(error), **observed)
    finally:
        guest.close()


def main(demo=DEMO, capture_guest=capture, description=__doc__):
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument('original', type=Path)
    parser.add_argument('native', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    original, native, out = (path.resolve() for path in (args.original, args.native, args.out))
    out.mkdir()
    shared = runpy.run_path('build/i386-demo-pulldown-v1/run.py')
    sha = shared['sha']
    pins = {str(path):sha(path) for path in (original, native, Path(demo).resolve())}
    working = out / 'working.img'
    shutil.copyfile(native, working)
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    with ThreadPoolExecutor(max_workers=2) as pool:
        jobs = {side:pool.submit(capture_guest, Guest, shared, image, out / side, side == 'native')
                for side, image in [('original', original), ('native', working)]}
        runs = {side: job.result() for side, job in jobs.items()}
    unchanged = all(sha(Path(path)) == expected for path, expected in pins.items())
    passed = unchanged and all(run['result'] == 'pass' for run in runs.values())
    (out / 'result.json').write_text(json.dumps(dict(
        result='pass' if passed else 'fail', input_sha256=pins, inputs_unchanged=unchanged,
        working_disk_sha256=sha(working), runs=runs), indent=2) + '\n')
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
