"""Activate the actual TextDemo entries in both guest environments."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import re
import time

from PIL import Image

root = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = (root/'Fixture.HC').read_bytes()
report = {'result': 'running', 'fixture_sha256': hashlib.sha256(fixture).hexdigest(),
          'scope': 'Physical mouse activation of the unchanged explicit Genesis link with editor dismissal and restored document roles'}
guest = None
try:
    if args.disk:
        image = out/'working.img'
        pack = runpy.run_path('tools/package-i386-native-image.py')['package']
        report['packaging'] = pack(args.disk, image, additions={'/Probe/TextDemo.HC': fixture})
    else:
        overlay = out/'overlay'
        runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference'](overlay)
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'+fixture)
        image = out/'original.iso'
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),
                        '--output',str(image)], check=True)
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    guest = Guest(image, out/'guest', bool(args.disk))
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        guest.type('#include "C:/Probe/TextDemo.HC"')
        guest.press('ret')
    log = guest.wait('TEXTDEMO POINTER ')
    address = int(re.search(r'TEXTDEMO POINTER ([0-9A-F]+)\n',log)[1],16)
    helper = runpy.run_path('build/grmodels-menu-workflows-v1/run.py')
    check = runpy.run_path('tools/check-i386-autocomplete-numeric-pixels.py')
    font = check['font_bytes']()
    label = b'Genesis,1:1'
    deadline = time.monotonic() + 90
    positions = set()
    while time.monotonic() < deadline:
        guest.screenshot('ready')
        with Image.open(guest.out/'ready.png') as frame:
            pixels = frame.convert('RGB').load()
        for row in range(60):
            for column in range(81-len(label)):
                if all((pixels[(column+n)*8+x,row*8+y] != (255,255,255))
                       == bool(font[ch*8+y] & (1<<x))
                       for n,ch in enumerate(label) for y in range(7) for x in range(8)):
                    positions.add((row,column))
        if len(positions) == 2:
            break
        positions.clear()
        time.sleep(.5)
    if len(positions) != 2:
        raise ValueError('Expected both underlined TextDemo links')
    row, column = max(positions)
    helper['click'](guest, address, (column*8+3,row*8+3))
    observer_path = Path('build/grmodels-menu-workflows-v1/run.py').resolve()
    namespace = {'__file__': str(observer_path), '__name__': 'textdemo_observer'}
    code = observer_path.read_text().replace('time.monotonic() + 90','time.monotonic() + 480')
    exec(compile(code,str(observer_path),'exec'),namespace)
    namespace['wait_text'](guest,check,font,b'In the beginning','genesis')
    def cancel():
        guest.key('shift',True)
        guest.press('esc')
        guest.key('shift',False)
    cancel()
    helper['wait_text'](guest,check,font,b'OKAY','menu-return')
    cancel()
    guest.wait('TEXTDEMO MOUSE LINK RESTORED\n', timeout=180)
    if args.disk:
        guest.command('6*7;')
        report['arithmetic'] = guest.result_pixels()
    report.update(result='pass', link=True)
except Exception as error:
    report.update(result='fail', error=str(error))
    raise
finally:
    if guest:
        guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
