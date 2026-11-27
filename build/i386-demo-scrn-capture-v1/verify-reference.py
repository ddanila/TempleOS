"""Verify the saved screen and its replay in the pinned x64 guest."""
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import subprocess

from PIL import Image

ROOT = Path(__file__).resolve().parent
CAPTURE = ROOT / 'original'
receipt = json.loads((ROOT / 'original-result.json').read_text())


def checked_bytes(path, name):
    data = path.read_bytes()
    if hashlib.sha256(data).hexdigest() != receipt[name]:
        raise ValueError(f'Unexpected bytes in {path.name}')
    return data


checked_bytes(CAPTURE / 'demo-shot.gr.z', 'file_sha256')
raw = subprocess.check_output(['zstd', '-dc', str(CAPTURE / 'demo-shot.raw.zst')])
if hashlib.sha256(raw).hexdigest() != receipt['framebuffer_sha256']:
    raise ValueError('Decoded screen differs from the captured device context')
if len(raw) != 640 * 480 or sorted(set(raw)) != receipt['palette_indices']:
    raise ValueError('Captured screen has the wrong dimensions or palette indices')


def pixels(name):
    path = CAPTURE / (name + '.png')
    if hashlib.sha256(path.read_bytes()).hexdigest() != receipt['frames'][name]:
        raise ValueError(f'{name} screenshot differs from the receipt')
    with Image.open(path) as image:
        if image.size != (640, 480):
            raise ValueError('Screenshot has the wrong dimensions')
        return image.convert('RGB').get_flattened_data()


candidates = defaultdict(Counter)
for index, rgb in zip(raw, pixels('capture'), strict=True):
    candidates[index][rgb] += 1
palette = {index: counts.most_common(1)[0][0] for index, counts in candidates.items()}
matched = sum(palette[index] == rgb for index, rgb in zip(raw, pixels('replayed'), strict=True))
if matched < 307_170:
    raise ValueError('Replayed screen differs from the saved screen')
print(json.dumps({'result': 'pass', 'pixels': len(raw), 'matched': matched,
                  'different': len(raw) - matched}, indent=2))
