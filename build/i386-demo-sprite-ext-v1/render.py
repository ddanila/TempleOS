"""Capture the three external maps from the interactive guest prompts."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import runpy
import shutil


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original_iso', type=Path)
    parser.add_argument('native_image', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir()
    working = out / 'working.img'
    shutil.copyfile(args.native_image, working)
    guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    capture = runpy.run_path('build/i386-demo-sprite-raw-v1/render.py')['capture']
    capture.__globals__['SOURCE'] = '/Demo/Graphics/SpritePutExt.HC'
    with ThreadPoolExecutor(max_workers=2) as pool:
        original = pool.submit(capture, guest, args.original_iso.resolve(), out / 'original', False)
        native = pool.submit(capture, guest, working, out / 'native', True)
        original.result()
        native.result()


if __name__ == '__main__':
    main()
