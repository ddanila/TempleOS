"""Round-trip the TimeClock record through five different RedSea paths."""
import argparse
import runpy
from pathlib import Path

here = Path(__file__).resolve().parent
root = here.parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--disk', type=Path, required=True)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
pack = runpy.run_path(str(root / 'tools/package-i386-native-image.py'))['package']
image = args.out / 'working.img'
pack(args.disk, image, additions={
    '/Archive.DATA': (here.parent / 'i386-timeclock-read-paths-v1' / 'Archive.DATA').read_bytes(),
    '/WriteRead.HC': (here / 'Contract.HC').read_bytes(),
})
Guest = runpy.run_path(str(root / 'tools/test-i386-autocomplete-interaction.py'))['Guest']
guest = Guest(image, args.out / 'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/WriteRead.HC"')
    results = [line for line in guest.collect().splitlines() if ' READ ' in line]
    (args.out / 'guest-results.txt').write_text('\n'.join(results) + '\n')
    expected = (
        'C:/ProbeData.DATA',
        'C:/ProbeData.DATA.Z',
        'C:/Home/TimeClock/ProbeData.DATA',
        'C:/Home/TimeClock/ProbeData.DATA.Z',
        '~/TimeClock/TimeFile.DATA.Z',
    )
    if results != [f'{path} READ exact' for path in expected]:
        raise ValueError(f'Unexpected round-trip results: {results}')
finally:
    guest.close()
