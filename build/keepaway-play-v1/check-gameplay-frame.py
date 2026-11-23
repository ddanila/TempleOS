import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

from PIL import Image


root = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('native_run', type=Path, nargs='?', default=root/'native64')
args = parser.parse_args()
frames = {}
for profile, run in (('original', root/'original'), ('native64', args.native_run)):
    path = run/'guest/gameplay.png'
    with Image.open(path) as image:
        pixels = Counter(image.convert('RGB').get_flattened_data())
    frames[profile] = {
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'arena_yellow_pixels': pixels[(255, 255, 87)],
        'border_red_pixels': pixels[(168, 0, 0)],
    }

log = (args.native_run/'guest/debug.log').read_text()
allocation = re.search(r'PUBLIC ALLOC EXHAUSTED ([0-9A-F]{16})', log)
exception = re.search(r'WINMGR window exception ([0-9A-F]{16})', log)
if frames['original']['arena_yellow_pixels'] < 200_000:
    raise ValueError('Original capture is missing the KeepAway arena')
passed = (
    frames['native64']['arena_yellow_pixels'] >= 200_000
    and frames['native64']['border_red_pixels'] >= 1_000
    and not exception
)
report = {
    'result': 'pass' if passed else 'fail',
    'scope': 'KeepAway arena appearance and Window Manager exception check',
    'frames': frames,
    'native_allocation_request_bytes': int(allocation[1], 16) if allocation else None,
    'native_window_exception': exception[1] if exception else None,
}
print(json.dumps(report, indent=2))
raise SystemExit(0 if passed else 1)
