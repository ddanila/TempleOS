"""Open a runtime-emitted warning link and check the edited file on a scratch disk."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('image', type=Path)
parser.add_argument('warnings', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
contract = Path(__file__).with_name('Activate.HC')
files = {'/Probe/ActivateWarning.HC': contract.read_bytes(),
         '/Probe/ParenWarnings.DD': args.warnings.read_bytes()}
pack = runpy.run_path('tools/package-i386-native-image.py')
disk = args.out / 'working.img'
receipt = pack['package'](args.image, disk, additions=files)
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(disk, args.out / 'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/Probe/ActivateWarning.HC"')
    guest.command('ParenWarnLinkCheck;', timeout=60)
    guest.command('6*7;')
    fresh = guest.result_pixels()
finally:
    guest.close()
source = '/Demo/ParenWarn.HC'
before = pack['snapshot'](args.image.read_bytes())[1][source][2]
after = pack['snapshot'](disk.read_bytes())[1][source][2]
expected = before.splitlines(keepends=True)
if not expected[8].startswith(b'd=(d1+d2)'):
    raise ValueError('Unexpected line nine in the source')
expected[8] = b'Z\x05' + expected[8]
if b''.join(expected) != after:
    raise ValueError('The editor did not insert at the warning source location')
report = {'result': 'pass', 'image_sha256': receipt['source_sha256'],
          'warnings_sha256': hashlib.sha256(files['/Probe/ParenWarnings.DD']).hexdigest(),
          'scope': 'Actual emitted line-nine DolDoc warning link opened the editor at the correct source line and restored the caller.',
          'fresh_result': fresh}
(args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
