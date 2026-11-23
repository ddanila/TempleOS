import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
root = Path(__file__).resolve().parent
fixture = (root/'Phases.HC').read_bytes()
if args.disk:
    image = out/'working.img'
    packer = runpy.run_path('tools/package-i386-native-image.py')['package']
    packer(args.disk, image, additions={'/TTFPhases.HC': fixture})
else:
    overlay = out/'overlay'
    reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
    reference['restore_reference'](overlay)
    (overlay/'Once.HC').write_bytes(
        b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
        b'#include "T:/Apps/ToTheFront/Load.HC"\n'
        b'U0 TTFReady(){U8 *p="TTF original loaded\\n";while(*p)OutU8(0xE9,*p++);}\n'
        b'TTFReady;\n' + fixture)
    image = out/'original.iso'
    subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                    '--output', str(image)], check=True)
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
exercise = runpy.run_path(str(root/'phase_workflow.py'))['exercise']
report = {'fixture_sha256': hashlib.sha256(fixture).hexdigest(),
          'input_sha256': hashlib.sha256((args.disk or image).read_bytes()).hexdigest()}
guest = Guest(image, out/'guest', bool(args.disk))
try:
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Apps/ToTheFront/Load.HC"')
        start = len(guest.collect())
        guest.type('#include "C:/TTFPhases.HC"')
        guest.press('ret')
        guest.wait('COMPILER BREAK ready', start=start)
        time.sleep(12)
    else:
        guest.wait('TTF original loaded\n', 90)
        time.sleep(6)
    report['phases'] = exercise(guest)
    if args.disk:
        guest.command('6*7;')
        report['after_match'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as error:
    report.update(result='fail', error=str(error)[:3000])
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
