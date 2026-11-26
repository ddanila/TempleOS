"""Check the rendered ExtChars glyph on both guests."""
import hashlib
import json
from pathlib import Path
import runpy

from PIL import Image

root = Path(__file__).resolve().parent
probe = runpy.run_path('tools/check-i386-autocomplete-numeric-pixels.py')
font = probe['font_bytes']()
label = b'Face:'
expected_rows = [0x3C, 0x42, 0xA5, 0x81, 0xC3, 0xBD, 0x42, 0x3C]
guests = {}
for name in ('original', 'native'):
    path = root/'comparison'/name/'glyph.png'
    with Image.open(path) as frame:
        pixels = frame.convert('RGB').load()
    hits = []
    for row in range(60):
        for column in range(80-len(label)):
            ink = probe['text_at'](pixels, font, label, column, row)
            if not ink or len(ink) != 1:
                continue
            glyph_col = column+len(label)
            glyph = [sum((pixels[glyph_col*8+x, row*8+y] == ink[0]) << x
                         for x in range(8)) for y in range(8)]
            hits.append({'column': glyph_col, 'row': row, 'rows': glyph})
    if len(hits) != 1 or hits[0]['rows'] != expected_rows:
        raise ValueError(f'Incorrect {name} glyph: {hits}')
    guests[name] = {**hits[0], 'frame_sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
(root/'glyph-result.json').write_text(json.dumps({'result': 'pass', 'guests': guests}, indent=2)+'\n')
