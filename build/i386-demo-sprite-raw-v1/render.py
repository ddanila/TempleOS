"""Draw SpriteRaw from the original and native interactive prompts."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

from PIL import Image

SOURCE = '/Demo/Graphics/SpriteRaw.HC'
GREEN = (0, 168, 0)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def capture(guest_type, image, out, native):
    guest = guest_type(image, out, native, reference_cpus=1)
    try:
        if native:
            guest.wait('DONE native kernel startup\n')
            guest.command(f'ExeFile("C:{SOURCE}");')
        else:
            guest.wait('DEMO BATCH READY\n')
            guest.type(f'ExeFile("T:{SOURCE}");')
            guest.press('ret')
        time.sleep(4)
        guest.screenshot('sprite')
    finally:
        guest.close()


def drawing(frame):
    with Image.open(frame) as image:
        width, height = image.size
        pixels = image.convert('RGB')
        green = {(x, y) for y in range(height) for x in range(width) if pixels.getpixel((x, y)) == GREEN}
    biggest = set()
    while green:
        stack = [green.pop()]
        component = set(stack)
        while stack:
            x, y = stack.pop()
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    neighbor = x + dx, y + dy
                    if neighbor in green:
                        green.remove(neighbor)
                        stack.append(neighbor)
                        component.add(neighbor)
        if len(component) > len(biggest):
            biggest = component
    if not biggest:
        raise ValueError('No green drawing in the screenshot')
    left = min(x for x, _ in biggest)
    top = min(y for _, y in biggest)
    return {(x - left, y - top) for x, y in biggest}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original_iso', type=Path)
    parser.add_argument('native_image', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    images = [p.resolve() for p in (args.original_iso, args.native_image)]
    before = [sha(p) for p in images]
    out = args.out.resolve()
    out.mkdir()
    disk = out / 'working.img'
    shutil.copyfile(images[1], disk)
    guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    with ThreadPoolExecutor(max_workers=2) as executor:
        original = executor.submit(capture, guest, images[0], out / 'original', False)
        native = executor.submit(capture, guest, disk, out / 'native', True)
        original.result()
        native.result()
    frames = {side: out / side / 'sprite.png' for side in ('original', 'native')}
    masks = {side: drawing(path) for side, path in frames.items()}
    if [sha(p) for p in images] != before:
        raise ValueError('An input image changed')
    widths = {side: 1 + max(x for x, _ in mask) for side, mask in masks.items()}
    heights = {side: 1 + max(y for _, y in mask) for side, mask in masks.items()}
    matched = masks['original'] == masks['native']
    sizes = {side: len(mask) for side, mask in masks.items()}
    passed = matched and all(100 <= size <= 101 for size in (*widths.values(), *heights.values()))
    receipt = dict(result='pass' if passed else 'fail', original_iso_sha256=before[0],
                   native_image_sha256=before[1], widths=widths, heights=heights,
                   green_pixels=sizes, mask_xor=len(masks['original'] ^ masks['native']),
                   screenshots_sha256={side: sha(path) for side, path in frames.items()})
    (out / 'result.json').write_text(json.dumps(receipt, indent=2) + '\n')
    if not passed:
        raise SystemExit('Sprite masks differ or have unexpected dimensions')


if __name__ == '__main__':
    main()
