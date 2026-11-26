"""Measure repeated original report and duplicate punch allocations in QEMU."""
import argparse
from pathlib import Path
import runpy
import subprocess

here = Path(__file__).resolve().parent
root = here.parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
contract = (here / 'Contract.HC').read_bytes()
if args.disk:
    image = args.out / 'working.img'
    package = runpy.run_path(str(root / 'tools/package-i386-native-image.py'))['package']
    package(args.disk, image, additions={
        '/TimeResources.HC': b'#include "C:/Apps/TimeClock/Load.HC"\n' + contract,
    })
else:
    overlay = args.out / 'reference'
    ref = runpy.run_path(str(root / 'tools/test-i386-timeclock-reference.py'))
    ref['restore_reference'](overlay)
    (overlay / 'Once.HC').write_bytes(
        b'Cd("B:/");DirMk("B:/Home");HomeSet("B:/Home");\n'
        b'#include "T:/Apps/TimeClock/Load.HC"\n' + contract +
        b'if(TimeResourceTrial)TimeResourceTrace("TIMECLOCK RESOURCE passed\\n");\n')
    image = args.out / 'reference.iso'
    subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                    '--output', str(image)], cwd=root, check=True)

Guest = runpy.run_path(str(root / 'tools/test-i386-autocomplete-interaction.py'))['Guest']
guest = Guest(image, args.out / 'guest', bool(args.disk))
try:
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/TimeResources.HC"')
        guest.command("if(!TimeResourceTrial)throw('Heap',TRUE);")
        guest.command('6*7;')
        guest.result_pixels()
    guest.wait('TIMECLOCK RESOURCE data=0 code=0 same=1\n', 30)
finally:
    lines = guest.collect().splitlines()
    (args.out / 'resource.txt').write_text(
        ''.join(f'{line}\n' for line in lines if line.startswith('TIMECLOCK RESOURCE ')))
    guest.close()
