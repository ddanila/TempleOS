"""Drive the bundled Logic launcher through its physical keyboard workflow."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import time

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
if args.disk:
    image = args.out/'working.img'
    shutil.copyfile(args.disk,image)
else:
    overlay = args.out/'reference'
    reference = runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
    reference['restore_reference'](overlay)
    (overlay/'Once.HC').write_bytes(
        b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
        b'#include "T:/Apps/Logic/Run.HC"\n'
        b'U8 *logic_exit="LOGIC cold returned\\n";while(*logic_exit)OutU8(0xE9,*logic_exit++);\n')
    image = args.out/'original.iso'
    subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),
                    '--output',str(image)],cwd=ROOT,check=True)
guest_helper = runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))
Guest = guest_helper['Guest']
pixels_helper = runpy.run_path(str(ROOT/'tools/check-i386-autocomplete-numeric-pixels.py'))
font = pixels_helper['font_bytes']()
result = {'result':'fail','input_sha256':hashlib.sha256(image.read_bytes()).hexdigest()}
guest = Guest(image, args.out/'guest', bool(args.disk))


def prompt(needle):
    deadline = time.monotonic()+35
    encoded = needle.encode('ascii')
    while time.monotonic()<deadline:
        guest.screenshot('prompt')
        with Image.open(guest.out/'prompt.png') as frame:
            rgb = frame.convert('RGB')
        for mode in (rgb,ImageOps.invert(rgb)):
            pixels = mode.load()
            for row in range(60):
                for column in range(81-len(encoded)):
                    if pixels_helper['text_at'](pixels,font,encoded,column,row):
                        return
        time.sleep(.15)
    raise ValueError(f'Missing Logic prompt: {needle}')


try:
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        start = len(guest.collect())
        guest.type('#include "C:/Apps/Logic/Run.HC"')
        guest.press('ret')
    for label,value in (('Gate:', 'AND'),('Gate:', ''),('Table size in hex','0x100'),
                        ('Input A:', '0xF0'),('Input B:', '0xCC'),('Input C:', ''),
                        ('Output A:', '0xC0'),('Output B:', '')):
        prompt(label)
        guest.type(value)
        guest.press('ret')
        time.sleep(.7)
    known = ROOT/'build/logic-lazy-load-v1/original/guest/and-design.png'
    box = (40,32,155,65)
    with Image.open(known) as reference:
        original = reference.convert('RGB').crop(box).tobytes()
    deadline = time.monotonic()+30
    while time.monotonic()<deadline:
        guest.screenshot('circuit')
        with Image.open(guest.out/'circuit.png') as frame:
            if frame.convert('RGB').crop(box).tobytes()==original:
                break
        time.sleep(.2)
    else:
        raise ValueError('Logic AND circuit differed from reference')
    guest.press('esc')
    if args.disk:
        guest.wait('COMMAND OK\n',20,start)
        guest.command('6*7;')
        result['arithmetic']=guest.result_pixels()
    else:
        guest.wait('LOGIC cold returned\n',20)
    result.update(result='pass',matching_circuit_pixels=3795,
                  circuit_sha256=hashlib.sha256(original).hexdigest())
except Exception as exc:
    result['error']=str(exc)
    raise
finally:
    guest.close()
    (args.out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
