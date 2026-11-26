"""Cancel an attempted overwrite of an existing directory report."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

from PIL import Image, ImageOps


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('saved_disk', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    disk = out / 'working.img'
    shutil.copyfile(args.saved_disk, disk)
    source_sha256 = sha(args.saved_disk)
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = vision['glyphs'](Path('Kernel/FontStd.HC'))
    guest = Guest(disk, out/'native', True)
    try:
        guest.wait('DONE native kernel startup\n')
        guest.command('ExeFile("C:/Probe/TreeHarness.HC");')
        guest.command('FPSetup;')
        guest.command('FileWrite("Z:/Changed.TXT","new",3);')
        start = len(guest.collect())
        guest.type('ExeFile("C:/Demo/Dsk/FPrintF.HC");')
        guest.press('ret')
        frame = guest.out/'cancel-form.png'
        inverted = guest.out/'cancel-inverted.png'
        deadline = time.monotonic()+30
        while time.monotonic() < deadline:
            guest.screenshot('cancel-form')
            with Image.open(frame) as image:
                ImageOps.invert(image.convert('RGB')).save(inverted)
            if any(vision['matches'](path, 'FileName:', font, first_row=0)
                   for path in (frame, inverted)):
                break
            log = guest.collect()[start:]
            if 'INPUT REJECT ' in log or 'COMMAND OK\n' in log:
                raise ValueError('The demo exited before rendering its filename form')
            time.sleep(.5)
        else:
            raise TimeoutError('No filename form')
        guest.key('shift', True)
        try:
            guest.press('esc')
        finally:
            guest.key('shift', False)
        guest.wait('COMMAND OK\n', start=start)
        guest.command('6*7;')
        result = dict(result='pass', fresh_result=guest.result_pixels(),
                      input_sha256=source_sha256, form_sha256=sha(frame))
    finally:
        guest.close()
    result['disk_unchanged'] = sha(disk) == source_sha256 == sha(args.saved_disk)
    if not result['disk_unchanged']:
        raise ValueError('Cancelled form changed the saved disk')
    (out/'result.json').write_text(json.dumps(result,indent=2)+'\n')


if __name__ == '__main__':
    main()
