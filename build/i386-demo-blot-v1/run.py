"""Capture the unchanged Blot demo's final bitmap and return to the prompt."""
from pathlib import Path
import runpy

from PIL import Image


DEMO = 'Demo/Graphics/Blot.HC'


def bitmap_counts(path, native):
    with Image.open(path) as frame:
        image = frame.convert('RGB').crop((0, 80, 640 if native else 320, 460))
        pixels = image.getcolors(image.width * image.height)
    colors = dict((rgb, count) for count, rgb in pixels)
    return {name: colors.get(rgb, 0) for name, rgb in {
        'red': (168, 0, 0), 'blue': (0, 0, 168), 'yellow': (255, 255, 87)
    }.items()}


def capture(Guest, shared, image, out, native):
    guest = Guest(image, out, native, reference_cpus=1)
    observed = {}
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        shared['submit'](guest, f'ExeFile("{drive}:/{DEMO}");')
        vision = runpy.run_path('build/i386-demo-define-v1/qualify.py')
        font = vision['glyphs'](Path('Kernel/FontStd.HC'))
        before = shared['wait_frame'](guest, 'bitmap', 'PRESS A KEY', vision, font, start)
        counts = observed['bitmap_colors'] = bitmap_counts(before, native)
        if counts['yellow'] < 1200 or min(counts['red'], counts['blue']) < 200:
            raise ValueError(f'Expected stamped ring, cross and square: {counts}')
        guest.press('spc')
        if native:
            guest.wait('COMMAND OK\n', start=start)
            guest.command('6*7;')
            observed['fresh_arithmetic'] = guest.result_pixels()
        wait_for = runpy.run_path('build/i386-demo-slider-v1/run.py')['wait_for']

        def cleared():
            guest.screenshot('after-key')
            remaining = bitmap_counts(out / 'after-key.png', native)
            return remaining if remaining['yellow'] < counts['yellow'] // 2 else None

        observed['cleared_colors'] = wait_for(cleared, 'The bitmap remains after the exit key')
        return dict(result='pass', **observed)
    except (RuntimeError, TimeoutError, ValueError) as error:
        return dict(result='fail', error=str(error), **observed)
    finally:
        guest.close()


if __name__ == '__main__':
    compare = runpy.run_path('build/i386-demo-slider-v1/run.py')['main']
    compare(DEMO, capture, __doc__)
