"""Activate the actual TextDemo entries in both guest environments."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

root = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = (root/'Fixture.HC').read_bytes()
report = {'result': 'running', 'fixture_sha256': hashlib.sha256(fixture).hexdigest(),
          'scope': 'Actual parsed TextDemo button command and Bible link via DocEntryRun'}
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
    guest.wait('TEXTDEMO LINK READY\n')
    observe = runpy.run_path('build/grmodels-menu-workflows-v1/run.py')['wait_text']
    check = runpy.run_path('tools/check-i386-autocomplete-numeric-pixels.py')
    observe(guest, check, check['font_bytes'](), b'In the beginning', 'genesis')
    guest.press('esc')
    guest.wait('TEXTDEMO MASK 15\n')
    if args.disk:
        guest.command('6*7;')
        report['arithmetic'] = guest.result_pixels()
    report.update(result='pass', mask=15)
except Exception as error:
    report.update(result='fail', error=str(error))
    raise
finally:
    if guest:
        guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
