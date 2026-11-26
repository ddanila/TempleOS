"""Compare the original and native ScrnCodes captures."""
import hashlib
import json
from pathlib import Path

from PIL import Image

CAPTURE = Path(__file__).resolve().parent
ORIGINAL = CAPTURE.parent / 'i386-demo-scrncodes-v2' / 'original'
NATIVE = CAPTURE / 'native'


def capture_rows(directory):
    receipt = json.loads((directory / 'result.json').read_text())
    if receipt['result'] != 'pass':
        raise ValueError(f'Guest did not complete the workflow: {directory}')
    frame = directory / 'guest' / 'grid.png'
    if hashlib.sha256(frame.read_bytes()).hexdigest() != receipt['frame_sha256']:
        raise ValueError(f'Frame differs from receipt: {frame}')
    with Image.open(frame) as image:
        pixels = image.convert('RGB').load()
    left, top = receipt['origin']
    rows = []
    for char in range(256):
        x0 = 8 * (left + 2 * (char % 16))
        y0 = 8 * (top + 2 * (char // 16))
        glyph = []
        for y in range(8):
            row = 0
            for x in range(8):
                color = pixels[x0 + x, y0 + y]
                if color not in ((0, 0, 0), (255, 255, 255)):
                    raise ValueError(f'Unexpected glyph color: {frame}, character {char}')
                if color == (255, 255, 255):
                    row |= 1 << x
            glyph.append(row)
        rows.append(glyph)
    return receipt, rows


original, original_rows = capture_rows(ORIGINAL)
native, native_rows = capture_rows(NATIVE)
if original_rows != native_rows:
    raise ValueError('Original and native VGA glyph pixels differ')
if not native['inputs_unchanged'] or not native['arithmetic']:
    raise ValueError('Native post-dismissal command or input check failed')
print(json.dumps({
    'result': 'pass',
    'glyphs_equal': len(original_rows),
    'pixels_equal': len(original_rows) * 64,
    'original_origin': original['origin'],
    'native_origin': native['origin'],
    'original_frame_sha256': original['frame_sha256'],
    'native_frame_sha256': native['frame_sha256'],
    'native_input_sha256': native['input_sha256'],
    'native_arithmetic': native['arithmetic'],
    'native_inputs_unchanged': native['inputs_unchanged'],
    'scope': 'Unchanged demo after loading packaged autocomplete and task settings; cold direct include remains open.',
}, indent=2))
