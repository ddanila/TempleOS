"""Compare TimeClock's write sequence with direct writes on the same guest."""
import argparse
import runpy
import subprocess
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
    '/Sequence.HC': (here.parent / 'i386-timeclock-read-layer-v1' / 'Contract.HC').read_bytes(),
})
Guest = runpy.run_path(str(root / 'tools/test-i386-autocomplete-interaction.py'))['Guest']
socket = (args.out / 'gdb.sock').resolve()
guest = Guest(image, args.out / 'guest', True, native_options=('-gdb', f'unix:{socket},server=on,wait=off'))
debugger = None
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/Sequence.HC"')
    line = next(line for line in guest.collect().splitlines() if line.startswith('FILES '))
    base = int(line.split()[1], 16)
    with (args.out / 'gdb.log').open('w') as log:
        debugger = subprocess.Popen([
            'gdb', '-nx', '-batch', '-ex', f'target remote {socket}',
            '-ex', f'set $file_base = {base:#x}', '-x', str(here / 'trace.gdb')
        ], stdout=log, stderr=subprocess.STDOUT)
        guest.command('CheckTimeWriteSequence;')
    guest.command('6*7;')
finally:
    guest.close()
    if debugger is not None:
        debugger.wait(timeout=15)
    lines = (args.out / 'guest' / 'debug.log').read_text().splitlines()
    (args.out / 'guest-results.txt').write_text(
        ''.join(f'{line}\n' for line in lines if line.startswith('SEQUENCE ')))
