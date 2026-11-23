import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('VertexMath.HC').read_bytes()
report = {'fixture_sha256': hashlib.sha256(fixture).hexdigest()}
if args.disk:
    image = out / 'working.img'
    packer = runpy.run_path('tools/package-i386-native-image.py')
    report['package'] = packer['package'](args.disk, image, additions={'/VertexMath.HC': fixture})
else:
    overlay = out / 'overlay'
    reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
    reference['restore_reference'](overlay)
    (overlay / 'Once.HC').write_bytes(fixture)
    image = out / 'original.iso'
    subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                    '--output', str(image)], check=True)
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out / 'guest', bool(args.disk))
try:
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/VertexMath.HC"')
    guest.wait('BALL math ready\n', 90)
    data = (out / 'guest/BallVertexMath.bin').read_bytes()
    if len(data) != 128 * 72:
        raise ValueError('Unexpected sample record size')
    report.update(result='pass', sample_sha256=hashlib.sha256(data).hexdigest())
except Exception as error:
    report.update(result='fail', error=str(error))
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
