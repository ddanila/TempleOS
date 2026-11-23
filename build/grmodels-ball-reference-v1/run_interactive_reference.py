import argparse
import json
from pathlib import Path
import runpy
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
overlay = out / 'overlay'
fixture = Path(__file__).with_name('Interactive.HC')
reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
sources = reference['restore_reference'](overlay)
(overlay / 'Once.HC').write_bytes(
    b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
    b'#include "T:/Apps/GrModels/Load.HC"\n'
    + fixture.read_bytes() + b'\nBallUIProbe;\n')
image = out / 'original.iso'
subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                '--output', str(image)], check=True)
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out / 'guest', False)
report = {'application_sha256': {path: sha for path, sha in sources.items()
                                 if path.startswith('Apps/GrModels/')}}
try:
    report['ball_mesh'] = runpy.run_path(str(fixture.with_name('interactive.py')))['exercise'](guest)
    report['result'] = 'pass'
except Exception as error:
    report.update(result='fail', error=str(error))
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
