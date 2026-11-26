"""Retry a failed image with only the TimeClock self-entry name normalized."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('source', type=Path)
parser.add_argument('--out', required=True, type=Path)
args = parser.parse_args()
args.out.mkdir()
image = bytearray(args.source.read_bytes())
original_sha = hashlib.sha256(image).hexdigest()
root = struct.unpack_from('<q', image, 2048 * 512 + 24)[0]


def child(block, name):
    start = block * 512
    size = struct.unpack_from('<q', image, start + 48)[0]
    for offset in range(start + 128, start + size, 64):
        attr, field, pointer = struct.unpack_from('<H38sq', image, offset)
        if attr == 0x810 and field.split(b'\0', 1)[0] == name:
            return pointer
    raise ValueError(f'Directory entry missing: {name!r}')


block = child(child(root, b'Home'), b'TimeClock')
start = block * 512
attr, name, self_block, length = struct.unpack_from('<H38sqq', image, start)
if (attr, name.rstrip(b'\0'), self_block, length) != (0x810, b'TimeClock', block, 512):
    raise ValueError('Unexpected directory self record')
image[start + 2:start + 40] = b'.'.ljust(38, b'\0')
working = args.out / 'working.img'
working.write_bytes(image)
repo = Path(__file__).resolve().parents[3]
Guest = runpy.run_path(str(repo / 'tools/test-i386-autocomplete-interaction.py'))['Guest']
guest = Guest(working, args.out / 'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('U8 *p=FileRead("~/TimeClock/TimeFile.DATA.Z");if(!p)throw(\'Read\',TRUE);Free(p);')
    guest.command('6*7;')
    result = guest.result_pixels()
finally:
    guest.close()
(args.out / 'result.json').write_text(json.dumps({
    'result': 'pass',
    'source_sha256': original_sha,
    'directory_block': block,
    'changed_name': ['TimeClock', '.'],
    'arithmetic': result,
}, indent=2) + '\n')
