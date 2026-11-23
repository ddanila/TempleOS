import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--visibility-fixture', action='store_true')
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
overlay = out / 'overlay'
reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
sources = reference['restore_reference'](overlay)
source = (
    b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
    b'#include "T:/Apps/ToTheFront/Load.HC"\n'
    b'U0 TTFReferenceLog(U8 *s){while(*s)OutU8(0xE9,*s++);}\n'
    b'TTFReferenceLog("TTF original loaded\\n");\n')
if args.visibility_fixture:
    source += Path(__file__).with_name('Visibility.HC').read_bytes()
else:
    source += (b'ToTheFront;\n'
               b'TTFReferenceLog("TTF original returned\\n");\n')
(overlay/'Once.HC').write_bytes(source)
image = out/'original.iso'
subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                '--output', str(image)], check=True)
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out/'guest', False)
report = {'application_sha256': {name: digest for name, digest in sources.items()
                                 if name.startswith('Apps/ToTheFront/')},
          'iso_sha256': hashlib.sha256(image.read_bytes()).hexdigest()}
try:
    guest.wait('TTF original loaded\n', 120)
    if args.visibility_fixture:
        guest.wait('TTF visibility captured\n', 60)
        report['visibility'] = struct.unpack('<12q', (guest.out/'TTFVisibility.bin').read_bytes())
        report['result'] = 'pass'
    else:
        time.sleep(6)
        guest.screenshot('entry')
        report['result'] = 'observed'
except Exception as error:
    report.update(result='fail', error=str(error))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
