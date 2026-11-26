"""Exercise the bundled mouse callback demo by selecting its rendered entries."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import runpy
import re
import struct
import shutil
import time

from PIL import Image


SOURCE = Path('Demo/DolDoc/ClickCallBack.HC')


def pointer(guest, address):
    path = guest.out / 'pointer.bin'
    guest.call('pmemsave', val=address, size=16, filename=str(path))
    return struct.unpack('<2q', path.read_bytes())


def click_link(frame, font):
    with Image.open(frame) as image:
        pixels = image.convert('RGB').load()
        return [(col, row)
                for row in range(image.height // 8)
                for col in range(image.width // 8 - len('lick Me') + 1)
                if all((pixels[(col + index)*8 + x, row*8 + y] != (255, 255, 255))
                       == bool(font[ord(character)][y] & (1 << x))
                       for index, character in enumerate('lick Me')
                       for y in range(7) for x in range(8))]


def click_label(guest, address, episode, font, matches, count=None):
    target = None
    for attempt in range(32):
        name = f'{episode}-{attempt}'
        guest.screenshot(name)
        frame = guest.out / f'{name}.png'
        if target is None:
            if count is None:
                hits = click_link(frame, font)
            else:
                headers = matches(frame, f'lick {count} more times', font, first_row=0)
                hits = [(col, row+3) for col, row in headers]
            if not hits:
                time.sleep(.2)
                continue
            col, row = hits[0]
            target = (col*8 + 22, row*8 + 4)
        x, y = pointer(guest, address)
        dx, dy = target[0]-x, target[1]-y
        if abs(dx) <= 2 and abs(dy) <= 1:
            for down in (True, False):
                guest.call('input-send-event', events=[
                    {'type': 'btn', 'data': {'button': 'left', 'down': down}}])
                time.sleep(.08)
            return {'observed_pointer': [x, y], 'target': target, 'frame': name}
        guest.call('input-send-event', events=[
            {'type': 'rel', 'data': {'axis': axis, 'value': max(-100, min(100, delta))}}
            for axis, delta in (('x', dx), ('y', dy))])
        time.sleep(.28)
    raise ValueError(f'Pointer or rendered target unavailable during {episode}')


def capture(Guest, image, out, native, observer, vision):
    audio = out / 'speaker.wav'
    guest = Guest(image, out, native, reference_cpus=1, audio_wav=audio)
    result = {'clicks': []}
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        for command in (
            'I64 cc_mouse[2];',
            'U0 CCObserve(U8 *){while(TRUE){cc_mouse[0]=ms.pos.x;cc_mouse[1]=ms.pos.y;Sleep(25);}}',
            'U0 CCDebug(U8 *s){while(*s)OutU8(0xE9,*s++);}',
            'CCDebug(MStrPrint("CC STATE %X\\n",cc_mouse));Spawn(&CCObserve);',
        ):
            guest.type(command)
            guest.press('ret')
            time.sleep(.5)
        log = guest.wait('CC STATE ', timeout=15)
        address = int(re.search(r'CC STATE ([0-9A-F]+)', log)[1], 16)
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        guest.type(f'ExeFile("{drive}:/{SOURCE}");')
        guest.press('ret')
        time.sleep(3)
        font = vision['glyphs'](Path('Kernel/FontStd.HC'))
        for count in range(3, 0, -1):
            result['clicks'].append(click_label(guest, address, f'jiffies-{count}', font, vision['matches'], count))
            time.sleep(1)
        if native:
            guest.wait('COMMAND OK\n', timeout=15, start=start)
        # The last popup leaves the pointer over the native link's glyphs.
        guest.call('input-send-event', events=[
            {'type': 'rel', 'data': {'axis': 'x', 'value': 110}},
            {'type': 'rel', 'data': {'axis': 'y', 'value': 64}},
        ])
        time.sleep(.3)
        result['clicks'].append(click_label(guest, address, 'sweep', font, vision['matches']))
        time.sleep(1)
        guest.screenshot('after-click')
        result['after_click_sha256'] = observer['sha'](out / 'after-click.png')
        if native:
            guest.command('6*7;')
            result['fresh_result'] = guest.result_pixels()
    except (RuntimeError, TimeoutError, ValueError) as error:
        result['error'] = str(error)
    finally:
        guest.close()
    result['tone_windows'] = observer['frequencies'](audio)
    result['audio_sha256'] = observer['sha'](audio)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path)
    parser.add_argument('native', type=Path)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    output = args.out.resolve()
    output.mkdir()
    native = output / 'working.img'
    shutil.copyfile(args.native, native)
    observer = runpy.run_path('build/i386-demo-menu-buttons-v1/run.py')
    vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
    Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
    inputs = {str(p.resolve()): observer['sha'](p) for p in (args.original, args.native, SOURCE)}
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = {side: pool.submit(capture, Guest, image, output / side, side == 'native', observer, vision)
                   for side, image in (('original', args.original.resolve()), ('native', native))}
        runs = {side: future.result() for side, future in futures.items()}
    unchanged = all(observer['sha'](Path(path)) == digest for path, digest in inputs.items())
    (output / 'result.json').write_text(json.dumps(dict(input_sha256=inputs, inputs_unchanged=unchanged,
                                                       runs=runs), indent=2)+'\n')


if __name__ == '__main__':
    main()
