"""Compare both physical scrollbar drags in the bundled ScrollBars demo."""
from pathlib import Path
import re
import runpy
import struct
import time

from PIL import Image

DEMO = 'Demo/Graphics/ScrollBars.HC'
POINTERS = r'''U0 SBPtrs(){U8*s=MStrPrint("\nSB PTR %X %X %X\n",&ms.pos,&Fs->pix_left,&Fs->horz_scroll),*p=s;while(*p)OutU8(0xE9,*p++);Free(s);}SBPtrs;'''
MARKER = re.compile(r'^SB PTR ([0-9A-F]+) ([0-9A-F]+) ([0-9A-F]+)\n', re.M)


def read(guest, address, layout, name):
    export = guest.out / f'{name}.bin'
    guest.call('pmemsave', val=address, size=struct.calcsize(layout), filename=str(export))
    return struct.unpack(layout, export.read_bytes())


def capture(Guest, shared, image, out, native):
    guest = Guest(image, out, native, reference_cpus=1)
    observed = {}
    wait_for = runpy.run_path('build/i386-demo-slider-v1/run.py')['wait_for']
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        shared['submit'](guest, POINTERS)
        marker = wait_for(lambda: MARKER.search(guest.collect()), 'Missing scrollbar addresses')
        pointer, geometry, scroll = (int(value, 16) for value in marker.groups())
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        shared['submit'](guest, f'Seed(1);ExeFile("{drive}:/{DEMO}");')

        def state():
            log = guest.collect()[start:]
            if 'INPUT REJECT ' in log:
                raise ValueError(log[-1600:])
            fields = read(guest, scroll, '<3q8x3q', 'scroll')
            return fields[1], fields[4], fields[2], fields[5]

        def ready():
            positions = state()
            if min(positions[2:]) > 1000:
                return positions
            return None

        observed['initial'] = wait_for(ready, 'Map callback did not publish its scroll range')
        x, _, width, y, _, height = read(guest, geometry, '<6q', 'geometry')
        if observed['initial'] != (0, 0, 2048 - width, 2048 - height):
            raise ValueError(f'Unexpected initial map ranges: {observed["initial"]}')
        observed['geometry'] = [x, y, width, height]
        time.sleep(1)
        guest.screenshot('map-initial')
        for axis, origin, end in (
            (0, (x, y + height + 4), (x + width // 4, y + height + 4)),
            (1, (x + width + 4, y), (x + width + 4, y + height // 4)),
        ):
            before = state()
            shared['move'](guest, pointer, origin)
            guest.call('input-send-event', events=[
                {'type': 'btn', 'data': {'button': 'left', 'down': True}}])
            try:
                time.sleep(.5)
                shared['move'](guest, pointer, end)

                def moved():
                    current = state()
                    if current[axis + 2] * .20 <= current[axis] <= current[axis + 2] * .30:
                        return current
                    return None

                during = wait_for(moved, f'Scrollbar {axis} did not track the drag')
            finally:
                guest.call('input-send-event', events=[
                    {'type': 'btn', 'data': {'button': 'left', 'down': False}}])
            time.sleep(.5)
            after = state()
            if after != during or after[1 - axis] != before[1 - axis]:
                raise ValueError(f'Scrollbar {axis} did not keep its value on release')
            observed[f'after_axis_{axis}'] = after
            name = f'map-axis-{axis}'
            guest.screenshot(name)
            with Image.open(out / f'{name}.png') as current, Image.open(
                    out / ('map-initial.png' if axis == 0 else 'map-axis-0.png')) as previous:
                viewport = (x + 8, y + 8, x + width - 8, y + height - 8)
                if current.crop(viewport).tobytes() == previous.crop(viewport).tobytes():
                    raise ValueError(f'Map raster did not change after dragging axis {axis}')
        guest.press('spc')
        if native:
            guest.wait('COMMAND OK\n', start=start)
            guest.command('6*7;')
            observed['fresh_arithmetic'] = guest.result_pixels()
        return dict(result='pass', **observed)
    except (RuntimeError, TimeoutError, ValueError) as exc:
        return dict(result='fail', error=str(exc), **observed)
    finally:
        guest.close()


if __name__ == '__main__':
    compare = runpy.run_path('build/i386-demo-slider-v1/run.py')['main']
    compare(DEMO, capture, __doc__)
