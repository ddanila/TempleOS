"""Exercise the bundled pull-down menu with physical mouse and keyboard input."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import re
import runpy
import shutil
import struct
import time

from PIL import Image, ImageOps


SOURCE = Path('Demo/PullDownMenu.HC')
POSITION = ('U0 PMPosition(){U8*s=MStrPrint("\\nPM POS %X\\n",&ms.pos),*q=s;'
            'while(*q)OutU8(0xE9,*q++);Free(s);}PMPosition;')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def submit(guest, command):
    guest.type(command)
    guest.press('ret')


def move(guest, address, target):
    capture = guest.out/'mouse.bin'
    for _ in range(32):
        guest.call('pmemsave', val=address, size=16, filename=str(capture))
        point = struct.unpack('<2q', capture.read_bytes())
        dx, dy = (want - got for want, got in zip(target, point))
        if abs(dx) <= 2 and abs(dy) <= 1:
            return point
        guest.call('input-send-event', events=[
            {'type':'rel','data':{'axis':axis,'value':max(-100,min(100,delta))}}
            for axis, delta in (('x',dx),('y',dy))])
        time.sleep(.18)
    raise TimeoutError(f'Mouse did not reach {target}')


def wait_frame(guest, name, phrase, vision, font, start, *, menu_row=None, previous_colors=None):
    deadline = time.monotonic()+30
    while time.monotonic() < deadline:
        log = guest.collect()[start:]
        if 'INPUT REJECT ' in log:
            raise ValueError(log[-1600:])
        guest.screenshot(name)
        frame = guest.out/f'{name}.png'
        if menu_row is not None:
            with Image.open(frame) as image:
                pixels = image.convert('RGB').load()
                colors = (set(), set())
                for col, letter in enumerate(phrase.encode('ascii')):
                    for y, mask in enumerate(font[letter]):
                        for x in range(8):
                            colors[bool(mask & (1 << x))].add(
                                pixels[88 + col * 8 + x, menu_row * 8 + y])
                if all(len(group) == 1 for group in colors) and colors[0] != colors[1]:
                    palette = tuple(next(iter(group)) for group in colors)
                    if previous_colors is None or palette != previous_colors:
                        return frame, palette
            time.sleep(.4)
            continue
        inverse = guest.out/'inverted.png'
        with Image.open(frame) as image:
            ImageOps.invert(image.convert('RGB')).save(inverse)
        if any(vision['matches'](candidate,phrase,font,first_row=0)
               for candidate in (frame,inverse)):
            return frame
        time.sleep(.4)
    raise TimeoutError(f'{name}: {phrase!r} not visible')


def capture(Guest, image, out, native):
    guest = Guest(image,out,native,reference_cpus=1)
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    font = vision['glyphs'](Path('Kernel/FontStd.HC'))
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        submit(guest, POSITION)
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            log = guest.collect()
            marker = re.search(r'^PM POS ([0-9A-F]+)\n', log, re.M)
            if marker:
                break
            time.sleep(.1)
        if not marker:
            raise TimeoutError('Missing complete mouse position address')
        address = int(marker.group(1), 16)
        start = len(log)
        drive = 'C' if native else 'T'
        submit(guest, f'ExeFile("{drive}:/{SOURCE}");')
        ready = wait_frame(guest,'ready','A pull-down menu',vision,font,start)
        frames = [ready]
        clicks = []
        for item, row in ((1,20),(2,28)):
            at_top = move(guest,address,(108,3))
            menu, palette = wait_frame(guest, f'menu-{item}', f'Opt{item}',
                                       vision, font, start, menu_row=item + 1)
            frames.append(menu)
            guest.call('input-send-event',events=[{'type':'btn','data':{'button':'left','down':True}}])
            try:
                # The original window manager latches the press on the menu bar.
                time.sleep(1)
                at_item = move(guest, address, (124, row))
                highlight, _ = wait_frame(
                    guest, f'highlight-{item}', f'Opt{item}', vision, font, start,
                    menu_row=item + 1, previous_colors=palette)
                frames.append(highlight)
            finally:
                guest.call('input-send-event',events=[{'type':'btn','data':{'button':'left','down':False}}])
            clicks.append(dict(top=at_top,item=at_item))
            frames.append(wait_frame(guest,f'option-{item}',f'Option # {item}',vision,font,start))
        move(guest,address,(250,200))
        guest.press('f1')
        frames.append(wait_frame(guest,'help','Test the menu.',vision,font,start))
        guest.key('shift',True)
        try:
            guest.press('f1')
        finally:
            guest.key('shift',False)
        frames.append(wait_frame(guest,'about','About PullDown Demo',vision,font,start))
        guest.key('shift',True)
        try:
            guest.press('esc')
        finally:
            guest.key('shift',False)
        result = dict(result='captured',clicks=clicks,
                      frames_sha256={frame.stem:sha(frame) for frame in frames})
        if native:
            guest.wait('COMMAND OK\n',start=start)
            guest.command('6*7;')
            result['fresh_result'] = guest.result_pixels()
        return result
    finally:
        guest.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original',type=Path)
    parser.add_argument('native',type=Path)
    parser.add_argument('out',type=Path)
    args = parser.parse_args()
    original,native,out = (path.resolve() for path in (args.original,args.native,args.out))
    out.mkdir()
    pins = {str(path):sha(path) for path in (original,native,SOURCE.resolve())}
    working = out/'working.img'
    shutil.copyfile(native,working)
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    runs = {}
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = {side:pool.submit(capture,Guest,image,out/side,side=='native')
                   for side,image in (('original',original),('native',working))}
        for side,future in futures.items():
            try:
                runs[side] = future.result()
            except (IndexError,RuntimeError,TimeoutError,ValueError) as error:
                runs[side] = dict(result='fail',error=str(error))
    unchanged = all(sha(Path(path))==digest for path,digest in pins.items())
    (out/'result.json').write_text(json.dumps(dict(inputs_unchanged=unchanged,input_sha256=pins,
                                                  working_disk_sha256=sha(working),runs=runs),
                                             indent=2)+'\n')


if __name__ == '__main__':
    main()
