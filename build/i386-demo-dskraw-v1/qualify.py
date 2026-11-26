"""Decode all 512 raw-sector bytes from the original and native VGA dumps."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy

from PIL import Image


ROW = re.compile(r'([0-9A-F]{8}) ((?:[0-9A-F]{2} ){16})')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def decode(path, font):
    glyphs = {font[ord(char)]: char for char in '0123456789ABCDEF '}
    rows = {}
    with Image.open(path) as image:
        pixels = image.convert('RGB').load()
        for y in range(0, image.height-7, 8):
            cells = []
            for x in range(0, image.width-7, 8):
                glyph = tuple(sum(1<<i for i in range(8)
                                  if pixels[x+i,y+j] != (255,255,255))
                              for j in range(8))
                cells.append(glyphs.get(glyph, '?'))
            match = ROW.search(''.join(cells))
            if match:
                offset = int(match[1],16)
                if offset < 512 and offset%16 == 0:
                    if offset in rows:
                        raise ValueError(f'Duplicate offset {offset:#x}')
                    rows[offset] = bytes.fromhex(match[2])
    if sorted(rows) != list(range(0,512,16)):
        raise ValueError(f'Incomplete dump in {path}: {sorted(rows)}')
    return b''.join(rows[i] for i in range(0,512,16))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    parser.add_argument('image', type=Path)
    args = parser.parse_args()
    receipt = json.loads((args.run/'result.json').read_bytes())
    disk = args.image.read_bytes()
    if not receipt['inputs_unchanged'] or sha(disk) != receipt['input_sha256'][str(args.image.resolve())]:
        raise ValueError('Input changed')
    if receipt['working_disk_sha256'] != sha(disk):
        raise ValueError('Native raw read changed the disk')
    working = args.run/'working.img'
    if working.is_file() and sha(working.read_bytes()) != receipt['working_disk_sha256']:
        raise ValueError('Native working disk changed after capture')
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font_path = Path('Kernel/FontStd.HC')
    font = vision['glyphs'](font_path)
    sectors = {}
    for side, expected in (('original', bytes(512)), ('native', disk[:512])):
        record = receipt['runs'][side]
        if record['result'] != 'captured':
            raise ValueError(f'{side}: {record["error"]}')
        frame = args.run/side/'sector-dump.png'
        if sha(frame.read_bytes()) != record['screenshots_sha256']['sector-dump']:
            raise ValueError(f'Dump frame changed: {side}')
        sector = decode(frame, font)
        if sector != expected:
            raise ValueError(f'Dump differs from sector zero: {side}')
        sectors[side] = sha(sector)
    print(json.dumps(dict(result='pass', bytes_per_sector=512, sectors_sha256=sectors,
                          native_disk_sha256=sha(disk), font_sha256=sha(font_path.read_bytes()),
                          fresh_result=receipt['runs']['native']['fresh_result']), indent=2))


if __name__ == '__main__':
    main()
