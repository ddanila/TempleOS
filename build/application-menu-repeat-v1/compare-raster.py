import hashlib
import json
from pathlib import Path

from PIL import Image


original = Path('build/application-menu-mouse-v1/original/guest')
native = Path('build/application-menu-integrated-v1/native64/guest')
checks = {
    'menu-heading': (0, 0, 640, 8),
    'menu-highlight': (0, 0, 72, 16),
}
receipt = {}
for name, box in checks.items():
    paths = [directory / f'{name}.png' for directory in (original, native)]
    regions = []
    for path in paths:
        with Image.open(path) as screen:
            regions.append(screen.convert('RGB').crop(box).tobytes())
    if regions[0] != regions[1]:
        raise ValueError(f'Menu raster differs in {name}')
    receipt[name] = {
        'box': box,
        'pixels': len(regions[0]) // 3,
        'rgb_sha256': hashlib.sha256(regions[0]).hexdigest(),
        'inputs': {str(path): hashlib.sha256(path.read_bytes()).hexdigest()
                   for path in paths},
    }
print(json.dumps({'result': 'pass', 'checks': receipt}, indent=2))
