"""Exercise ScrnCodes and capture its 256-character grid."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import time

from PIL import Image, ImageOps

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
native = bool(args.disk)
probe = runpy.run_path('tools/check-i386-autocomplete-numeric-pixels.py')
font = probe['font_bytes']()
report = {'result':'fail'}
guest = None

def sha(data):
    return hashlib.sha256(data).hexdigest()

try:
    if native:
        source = args.disk.read_bytes()
        report['input_sha256'] = sha(source)
        image = out/'working.img'
        image.write_bytes(source)
    else:
        overlay = out/'original-source'
        runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference'](overlay)
        (overlay/'Once.HC').write_text(r'''
while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;
#include "T:/Demo/ScrnCodes.HC"
U8 *scrncodes_st="SCRNCODES RETURNED\n";
while(*scrncodes_st)OutU8(0xE9,*scrncodes_st++);
''')
        image = out/'original.iso'
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],check=True)
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = Guest(image,out/'guest',native)
    if native:
        guest.wait('DONE native kernel startup\n')
        begin = len(guest.collect())
        guest.type('#include "C:/Demo/ScrnCodes.HC"')
        guest.press('ret')
    deadline = time.monotonic()+60
    while time.monotonic()<deadline:
        guest.screenshot('grid')
        with Image.open(guest.out/'grid.png') as frame:
            rgb = frame.convert('RGB')
        locations = []
        for variant in (rgb,ImageOps.invert(rgb)):
            pixels = variant.load()
            for row in range(8,30):
                for column in range(2,50):
                    if probe['text_at'](pixels,font,b'A',column,row):
                        left,top = column-2,row-8
                        if left+30>=80 or top+30>=60:
                            continue
                        if all(probe['text_at'](pixels,font,bytes((ch,)),left+(ch&15)*2,top+(ch//16)*2)
                               for ch in range(33,127)):
                            locations.append((left,top,pixels))
        if len(locations)==1:
            left,top,pixels = locations[0]
            break
        time.sleep(.5)
    else:
        raise ValueError('Missing aligned ScrnCodes grid')
    report['origin'] = [left,top]
    report['frame_sha256'] = sha((guest.out/'grid.png').read_bytes())
    report['glyph_rows'] = [
        [sum((pixels[(left+(ch&15)*2)*8+x,(top+(ch//16)*2)*8+y] != (255,255,255))<<x
             for x in range(8)) for y in range(8)] for ch in range(256)]
    guest.press('a')
    if native:
        guest.wait('COMMAND OK\n',60,begin)
        guest.command('6*7;')
        report['arithmetic'] = guest.result_pixels()
        report['inputs_unchanged'] = sha(args.disk.read_bytes()) == report['input_sha256']
    else:
        guest.wait('SCRNCODES RETURNED\n',60)
    report['result'] = 'pass'
except Exception as error:
    report['error'] = str(error)
    raise
finally:
    if guest:
        guest.close()
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
