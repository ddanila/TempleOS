"""Check SpritePutExt's imported DolDoc payloads and rendered maps."""
import argparse
import hashlib
from itertools import groupby
import json
from pathlib import Path
import runpy
import struct

from PIL import Image

HERE = Path(__file__).resolve().parent
DEMO = 'Demo/Graphics/SpritePutExt.HC'
ASSET = 'Demo/Graphics/SpritePut.HC'
GRAY = (87, 87, 87)
HEADER = struct.Struct('<4I')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def bins(data):
    text, null, tail = data.partition(b'\0')
    if not null:
        raise ValueError('Missing binary section')
    records = []
    while tail:
        number, flags, size, uses = HEADER.unpack_from(tail)
        if len(tail) < HEADER.size + size:
            raise ValueError('Truncated binary record')
        payload = tail[HEADER.size:HEADER.size + size]
        records.append((number, flags, uses, payload))
        tail = tail[HEADER.size + size:]
    return text, records


def maps(frame):
    with Image.open(frame) as image:
        rgb = image.convert('RGB')
        rows = [(y, [x for x in range(rgb.width) if rgb.getpixel((x, y)) == GRAY])
                for y in range(rgb.height)]
    masks = []
    for populated, run in groupby(rows, key=lambda row: bool(row[1])):
        if not populated:
            continue
        band = list(run)
        top = band[0][0]
        left = min(x for _, xs in band for x in xs)
        masks.append({(x - left, y - top) for y, xs in band for x in xs})
    return masks


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('native_image', type=Path)
    parser.add_argument('--batch', type=Path, required=True)
    args = parser.parse_args()
    batch_dir = args.batch
    batch = json.loads((batch_dir / 'result.json').read_text())
    entry = batch['entries'][DEMO]
    raw = args.native_image.read_bytes()
    if 'error' in batch or not batch['inputs_unchanged'] or batch['input_sha256'] != sha(raw):
        raise ValueError('The complete batch did not run against this image')
    asset = Path(ASSET).read_bytes()
    disk = runpy.run_path('tools/package-i386-native-image.py')['snapshot'](raw)[1]
    original_asset = batch_dir / 'original-source' / ASSET
    if asset != disk['/' + ASSET][2] or asset != original_asset.read_bytes():
        raise ValueError('The external source asset differs between guests')
    _, asset_bins = bins(asset)
    sprite = next(payload for num, _, _, payload in asset_bins if num == 2)
    expected_text = b''.join(f'US Map:$SP,"",BI={i}$'.encode('ascii') + b'\n' * 12
                             for i in range(1, 4)) + b'\x05'
    expected_bins = [(number, 0, 1, sprite) for number in range(1, 4)]
    drawings = {}
    screenshots = {}
    for side in ('original', 'native'):
        data = (batch_dir / side / entry['output_file']).read_bytes()
        if sha(data) != entry[side + '_sha256'] or bins(data) != (expected_text, expected_bins):
            raise ValueError(f'Imported binary records differ on {side}')
        frame = HERE / 'render' / side / 'sprite.png'
        drawings[side] = maps(frame)
        screenshots[side] = sha(frame.read_bytes())
    masks = drawings['original']
    if drawings['native'] != masks or len(masks) != 3 or any(mask != masks[0] for mask in masks):
        raise ValueError('The three rendered map silhouettes differ')
    print(json.dumps(dict(result='pass', image_sha256=batch['input_sha256'],
                          demo_sha256=entry['source_sha256'], asset_sha256=sha(asset),
                          sprite_sha256=sha(sprite), sprite_bytes=len(sprite),
                          document_bytes=entry['bytes'], sprites=len(masks),
                          gray_pixels=len(masks[0]), screenshots_sha256=screenshots), indent=2))


if __name__ == '__main__':
    main()
