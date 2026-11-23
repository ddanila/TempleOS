"""Exercise the pinned original X-Caliber launch, gun and exit."""

import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--loop-trace', action='store_true')
parser.add_argument('--input-trace', action='store_true')
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
if args.loop_trace and not args.input_trace:
    parser.error('--loop-trace requires --input-trace')
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC').read_bytes()
overlay = out / 'overlay'
reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
sources = reference['restore_reference'](overlay)
if args.input_trace:
    app = overlay / 'Apps/X-Caliber/X-Caliber.HC'
    source = app.read_bytes()
    offset = source.index(b'U0 XCaliber(')
    instrument = runpy.run_path(str(Path(__file__).with_name('input_trace.py')))['instrument']
    app.write_bytes(source[:offset] + instrument(source[offset:], loop=args.loop_trace))
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
if args.input_trace:
    report['instrumented_app_sha256'] = hashlib.sha256(app.read_bytes()).hexdigest()
try:
    exercise = runpy.run_path(str(Path(__file__).with_name('workflow.py')))['exercise']
    exercise(guest, report)
except Exception as error:
    report['error'] = str(error)
    raise
finally:
    if args.input_trace:
        report['input_trace'] = [line for line in guest.collect().splitlines()
                                 if line.startswith('XC ')]
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
