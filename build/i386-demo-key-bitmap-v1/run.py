"""Exercise the held-key animation and release cleanup in KeyBitMap.HC."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

from PIL import Image


SOURCE = Path('Demo/KeyBitMap.HC')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def ink(path):
    with Image.open(path) as image:
        pixels = image.convert('RGB').load()
        return {(x,y) for x in range(0,145) for y in range(90,165)
                if pixels[x,y] != (255,255,255)}


def capture(guest_type, vision, font, image, out, native):
    guest = guest_type(image, out, native, reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        guest.type(f'DocClear;ExeFile("{drive}:/{SOURCE}");')
        guest.press('ret')
        deadline = time.monotonic() + 20
        idle = out / 'before-hold.png'
        while time.monotonic() < deadline:
            log = guest.collect()[start:]
            if 'INPUT REJECT ' in log:
                raise ValueError(log[-1800:])
            guest.screenshot('before-hold')
            if vision['matches'](idle, 'ress and hold', font, first_row=0):
                break
            time.sleep(.3)
        else:
            raise TimeoutError('Missing held-key prompt')
        base = ink(idle)
        samples = []
        guest.key('i',True)
        try:
            for sample in range(1,5):
                time.sleep(.25)
                label = f'held-{sample}.png'
                guest.screenshot(f'held-{sample}')
                path = out / label
                delta = ink(path) - base
                samples.append(dict(frame=label, sha256=sha(path), pixels=len(delta),
                                    left=min((x for x,_ in delta),default=None)))
        finally:
            guest.key('i',False)
        if native:
            log = guest.wait('COMMAND OK\n', start=start)
            if 'INPUT REJECT ' in log[start:]:
                raise ValueError(log[start:][-1600:])
        time.sleep(2)
        guest.screenshot('after-release')
        after = out / 'after-release.png'
        if len({item['left'] for item in samples if item['pixels'] >= 5}) < 2:
            raise ValueError(f'No moving sprite in held frames: {samples}')
        if len(ink(after) - base) > 2:
            raise ValueError('Sprite remained after release')
        result = dict(result='pass', samples=samples, idle_sha256=sha(idle), after_release_sha256=sha(after))
        if native:
            guest.command('6*7;')
            result['fresh_result'] = guest.result_pixels()
        return result
    finally:
        guest.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original_iso',type=Path)
    parser.add_argument('native_image',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    original, native = (p.resolve() for p in (args.original_iso,args.native_image))
    pins = {str(p):sha(p) for p in (original,native,SOURCE.resolve())}
    disk = out / 'working.img'
    shutil.copyfile(native,disk)
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = vision['glyphs'](Path('Kernel/FontStd.HC'))
    guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    results = {}
    with ThreadPoolExecutor(max_workers=2) as pool:
        runs = {side:pool.submit(capture,guest,vision,font,image,out/side,side=='native')
                for side,image in (('original',original),('native',disk))}
        for side, run in runs.items():
            try:
                results[side] = run.result()
            except (ValueError,TimeoutError,RuntimeError) as error:
                results[side] = dict(result='fail',error=str(error))
    unchanged = all(sha(Path(path))==digest for path,digest in pins.items())
    passed = unchanged and all(result['result']=='pass' for result in results.values())
    report = dict(result='pass' if passed else 'fail', input_sha256=pins,
                  inputs_unchanged=unchanged,runs=results)
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if not passed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
