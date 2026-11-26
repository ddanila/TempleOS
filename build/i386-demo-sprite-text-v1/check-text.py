"""Independently decode SpriteText's bundled sprite into its two reports."""
import hashlib
import json
from pathlib import Path
import runpy
import struct

HERE = Path(__file__).resolve().parent
SOURCE = Path('Demo/Graphics/SpriteText.HC')
SUMMARIES = '$FG,5$**** LINE SUMMARIES ****$FG$\n'
SOURCE_CODE = '\n\n$FG,5$**** ENTIRE SPRITE CODE ****$FG$\n'


def reports(sprite):
    summaries, instructions = [], []
    pos = 0
    while sprite[pos]:
        kind = sprite[pos]
        pos += 1
        if kind == 1:
            color = {0: 'BLACK'}[sprite[pos]]
            pos += 1
            summary, code = f'Color {color}', f'Color{{{color}}}'
        elif kind == 2:
            assert sprite[pos:pos + 2] == bytes((6, 8))
            pos += 2
            summary, code = 'Dither Color BROWN/DKGRAY', 'Color{BROWN/DKGRAY}'
        elif kind == 3:
            width, = struct.unpack_from('<i', sprite, pos)
            pos += 4
            summary, code = f'Thick {width}', f'Thick{{{width}}}'
        elif kind in (4, 10, 12):
            x1, y1, x2, y2 = struct.unpack_from('<4i', sprite, pos)
            pos += 16
            name = {4: 'Planar Symmetry', 10: 'Line', 12: 'Rect'}[kind]
            summary = f'{name} ({x1},{y1}),({x2},{y2})'
            if kind == 12:
                code = f'Rect{{({x1},{y1}):({x2 - x1},{y2 - y1})}}'
            else:
                code = f'{name.replace(" ", "")}{{({x1},{y1}),({x2},{y2})}}'
        elif kind == 14:
            x, y, radius = struct.unpack_from('<3i', sprite, pos)
            pos += 12
            summary, code = f'Circle ({x},{y}):{radius}R', f'Circle{{({x},{y}):{radius}}}'
        elif kind == 9:
            count, x, y = struct.unpack_from('<3i', sprite, pos)
            pos += 12
            packed_length = (count * 3 + 7) // 8
            bits = int.from_bytes(sprite[pos:pos + packed_length], 'little')
            pos += packed_length
            steps = ''.join(str((bits >> (3 * i)) & 7) for i in range(count))
            chunks = [steps[:48]] + [steps[i:i + 64] for i in range(48, count, 64)]
            summary = f'PolyPoint {count} ({x},{y})'
            code = f'PolyPt{{({x},{y}),' + '\n'.join(chunks) + '}'
        else:
            raise ValueError(f'Unexpected sprite element {kind}')
        summaries.append(summary)
        instructions.append(code)
    if pos != len(sprite) - 1:
        raise ValueError('Unexpected characters after the sprite terminator')
    text = SUMMARIES + ''.join(line + '\n' for line in summaries)
    text += SOURCE_CODE + ''.join(line + ';\n' for line in instructions) + '\x05'
    return text.encode('ascii'), len(instructions)


def main():
    asset = SOURCE.read_bytes()
    read_bins = runpy.run_path('build/i386-demo-sprite-ext-v1/qualify.py')['bins']
    _, records = read_bins(asset)
    expected, count = reports(records[0][3])
    data = (HERE / 'comparison/original/demo-0.DD').read_bytes()
    if data != expected:
        raise ValueError('Report differs from the decoded sprite')
    print(json.dumps(dict(result='pass', records=count,
                          source_sha256=hashlib.sha256(asset).hexdigest(),
                          document_sha256=hashlib.sha256(data).hexdigest()), indent=2))


if __name__ == '__main__':
    main()
