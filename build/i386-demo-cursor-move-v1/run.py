"""Check all 100 DolDoc cursor-movement cells against their expected layout."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

from PIL import Image


SOURCE = Path('Demo/DolDoc/CursorMove.HC')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def table(frame, vision, font):
    starts = vision['matches'](frame, '000', font, first_row=0)
    lookup = {font[ch]: chr(ch) for ch in b'0123456789'}
    with Image.open(frame) as image:
        pixels = image.convert('RGB').load()
        for first_col, first_row in starts:
            if (first_col+39)*8 > image.width or (first_row+10)*8 > image.height:
                continue
            observed = []
            for row in range(first_row, first_row+10):
                cells = []
                for column in range(first_col, first_col+40, 4):
                    digits = []
                    for col in range(column,column+3):
                        mask = tuple(sum((pixels[col*8+x,row*8+y] != (255,255,255)) << x
                                         for x in range(8)) for y in range(8))
                        digits.append(lookup.get(mask,'?'))
                    cells.append(''.join(digits))
                observed.append(cells)
            expected = [[f'{col*10+row:03d}' for col in range(10)] for row in range(10)]
            if observed == expected:
                return dict(origin=[first_col,first_row],rows=observed)
    raise ValueError(f'No complete 10 by 10 column-major table in {frame}')


def capture(guest_type, vision, font, disk, out, native):
    guest = guest_type(disk,out,native,reference_cpus=1)
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        drive = 'C' if native else 'T'
        setup = 'WinBorder;WinMax;DocClear;'
        if native:
            guest.command(setup)
        else:
            guest.type(setup)
            guest.press('ret')
            time.sleep(2)
        start = len(guest.collect())
        guest.type(f'ExeFile("{drive}:/{SOURCE}");')
        guest.press('ret')
        if native:
            log = guest.wait('COMMAND OK\n',start=start)
            if 'INPUT REJECT ' in log[start:]:
                raise ValueError(log[start:][-1800:])
        time.sleep(3)
        guest.screenshot('table')
        path = out/'table.png'
        result = table(path,vision,font)
        result.update(result='pass',table_sha256=sha(path))
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
    parser.add_argument('--out',required=True,type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    original,native = (p.resolve() for p in (args.original_iso,args.native_image))
    font_path = Path('Kernel/FontStd.HC')
    pins = {str(p):sha(p) for p in (original,native,SOURCE.resolve(),font_path.resolve())}
    disk=out/'working.img'
    shutil.copyfile(native,disk)
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = vision['glyphs'](font_path)
    guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    results = {}
    with ThreadPoolExecutor(max_workers=2) as pool:
        runs = {side:pool.submit(capture,guest,vision,font,image,out/side,side=='native')
                for side,image in (('original',original),('native',disk))}
        for side,run in runs.items():
            try:
                results[side] = run.result()
            except (ValueError,TimeoutError,RuntimeError) as error:
                results[side] = dict(result='fail',error=str(error))
    unchanged = all(sha(Path(name))==digest for name,digest in pins.items())
    passed = unchanged and all(result['result']=='pass' for result in results.values())
    receipt = dict(result='pass' if passed else 'fail',input_sha256=pins,
                   inputs_unchanged=unchanged,runs=results)
    (out/'result.json').write_text(json.dumps(receipt,indent=2)+'\n')
    if not passed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
