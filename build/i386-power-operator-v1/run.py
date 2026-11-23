"""Compare executable HolyC power expressions on original and native guests."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys


# Exact values observed under the pinned original SYS_POW implementation.
EXPECTED = ['4021FFFFFFFFFFFF', '4020000000000000',
            '4007FFFFFFFFFFFF', '3FD0000000000000']


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', required=True, type=Path)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
probe = Path(__file__).with_name('Probe.HC').read_bytes()
if args.disk:
    packer = runpy.run_path('tools/package-i386-native-image.py')
    image = out / 'working.img'
    packer['package'](args.disk, image, additions={'/PowerProbe.HC': probe})
else:
    reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
    overlay = out / 'overlay'
    reference['restore_reference'](overlay)
    (overlay / 'Once.HC').write_bytes(
        b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n' + probe)
    image = out / 'original.iso'
    subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', str(overlay),
                    '--output', str(image)], check=True)
guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = guest_type(image, out / 'guest', bool(args.disk))
report = {'result': 'fail', 'fixture_sha256': hashlib.sha256(probe).hexdigest(),
          'input_sha256': hashlib.sha256((args.disk or image).read_bytes()).hexdigest()}
try:
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/PowerProbe.HC"')
    log = guest.wait('POWER values ', 80)
    values = re.search(r'^POWER values ((?:[0-9A-F]{16} ){3}[0-9A-F]{16})$', log, re.M)
    if values is None:
        raise ValueError('Missing power results')
    report['values'] = values[1].split()
    if report['values'] != EXPECTED:
        raise ValueError('Power values differ from the pinned original')
    report['result'] = 'pass'
except Exception as error:
    report['error'] = str(error)
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
