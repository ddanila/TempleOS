"""Activate the actual TextDemo entries in both guest environments."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import re
import time

root = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = (root/'Fixture.HC').read_bytes()
report = {'result': 'running', 'fixture_sha256': hashlib.sha256(fixture).hexdigest(),
          'scope': 'Physical click on the unchanged TextDemo button in the live document menu'}
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
    column, row = helper['wait_text'](guest, check, check['font_bytes'](), b'OKAY', 'ready')
    helper['click'](guest, address, (column*8+3,row*8+3))
    # A click sends Space to the entry. A double-click accepts it and
    # returns the result from the live menu.
    time.sleep(.5)
    if 'TEXTDEMO BUTTON CLICK 1\n' not in guest.collect():
        for down in (True, False, True, False):
            guest.call('input-send-event', events=[
                {'type':'btn', 'data':{'down':down,'button':'left'}},
            ])
            time.sleep(.08)
    guest.wait('TEXTDEMO BUTTON CLICK 1\n', timeout=45)
    if args.disk:
        guest.command('6*7;')
        report['arithmetic'] = guest.result_pixels()
    report.update(result='pass', button=1)
except Exception as error:
    report.update(result='fail', error=str(error))
    raise
finally:
    if guest:
        guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
