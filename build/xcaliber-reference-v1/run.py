"""Exercise the pinned original X-Caliber launch, gun and exit."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys
import time


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC').read_bytes()
overlay = out / 'overlay'
reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
sources = reference['restore_reference'](overlay)
(overlay / 'Once.HC').write_bytes(
    b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
    b'#include "T:/Apps/X-Caliber/Load.HC"\n' + fixture)
iso = out / 'original.iso'
subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', str(overlay),
                '--output', str(iso)], check=True)
guest_type = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = guest_type(iso, out / 'guest', False)
report = dict(result='fail', fixture_sha256=hashlib.sha256(fixture).hexdigest(),
              app_source_sha256=sources['Apps/X-Caliber/X-Caliber.HC'])
try:
    guest.wait('XC ready\n', 90)
    time.sleep(3)
    guest.screenshot('intro')
    log = guest.wait('XC pointer ', 10)
    pointer = re.search(r'^XC pointer ([0-9A-F]+)$', log, re.M)
    if pointer is None:
        raise ValueError('Missing popup pointer address')
    drag = runpy.run_path('build/tothefront-original-v1/phase_workflow.py')['drag']
    okay = (160, 156)
    drag(guest, int(pointer[1], 16), okay, okay)
    log = guest.wait('XC level ', 30)
    level = re.search(r'^XC level (\d+) enemies (\d+) score (\d+)$', log, re.M)
    if level is None:
        raise ValueError('Missing level state')
    report['level'], report['enemies'], report['score'] = map(int, level.groups())
    assert report['level'] == 1 and report['enemies'] > 0 and report['score'] == 0
    guest.screenshot('level')
    guest.press('ret')
    guest.wait('XC running\n', 20)
    guest.press('spc')
    guest.wait('XC gun fired\n', 20)
    report['gun_fired'] = True
    guest.screenshot('play')
    guest.press('esc')
    guest.wait('XC returned\n', 30)
    report.update(result='pass', returned=True)
except Exception as error:
    report['error'] = str(error)
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
