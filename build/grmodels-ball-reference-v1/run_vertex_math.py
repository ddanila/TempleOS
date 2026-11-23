import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--disk', type=Path)
parser.add_argument('--cosine-steps', action='store_true')
parser.add_argument('--product-conversion', action='store_true')
parser.add_argument('--wide-check', action='store_true')
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
if args.cosine_steps and not args.disk:
    parser.error('--cosine-steps requires a native --disk')
if sum((args.cosine_steps, args.product_conversion, args.wide_check)) > 1:
    parser.error('Select one math fixture')
out = args.out.resolve()
out.mkdir()
fixture_name, expected_size = 'VertexMath.HC', 128 * 72
if args.cosine_steps:
    fixture_name, expected_size = 'CosineSteps.HC', 12 * 8
if args.product_conversion:
    fixture_name, expected_size = 'ProductConversion.HC', 6 * 8
if args.wide_check:
    fixture_name, expected_size = 'WideProductCheck.HC', 16 * 8
fixture_path = Path(__file__).with_name(fixture_name)
fixture = fixture_path.read_bytes()
if args.wide_check and args.disk:
    helper = fixture_path.with_name('WideProduct.HC').read_bytes()
    fixture = helper + b'\n' + fixture.replace(
        b'return a*b;', b'return BallWideMultiplyToI64(a,b);')
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
    if len(data) != expected_size:
        raise ValueError('Unexpected sample record size')
    report.update(result='pass', sample_sha256=hashlib.sha256(data).hexdigest())
except Exception as error:
    report.update(result='fail', error=str(error))
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
