"""Compare the rotating, depth-buffered faces of the unchanged 3DPoly demo."""
from pathlib import Path
import runpy

from PIL import Image


DEMO = 'Demo/Graphics/3DPoly.HC'
COLORS = {'red': (168, 0, 0), 'green': (0, 168, 0), 'blue': (0, 0, 168)}


def masks(path, native):
    with Image.open(path) as frame:
        image = frame.convert('RGB')
        pixels = image.load()
        positions = {name: set() for name in COLORS}
        names = {color: name for name, color in COLORS.items()}
        for y in range(145, 460):
            for x in range(8, 640 if native else 320):
                name = names.get(pixels[x, y])
                if name is not None:
                    positions[name].add((x, y))
    return positions


def capture(Guest, shared, image, out, native):
    guest = Guest(image, out, native, reference_cpus=1)
    result = {}
    slider = runpy.run_path('build/i386-demo-slider-v1/run.py')
    wait_for = slider['wait_for']
    try:
        guest.wait('DONE native kernel startup\n' if native else 'DEMO BATCH READY\n')
        guest.screenshot('baseline')
        baseline = masks(out / 'baseline.png', native)
        start = len(guest.collect())
        drive = 'C' if native else 'T'
        shared['submit'](guest, f'ExeFile("{drive}:/{DEMO}");')

        def next_frame(name, previous):
            log = guest.collect()[start:]
            if 'INPUT REJECT ' in log:
                raise ValueError(log[-1600:])
            guest.screenshot(name)
            current = masks(out / f'{name}.png', native)
            if max(len(current[color] - baseline[color]) for color in COLORS) < 300:
                return None
            if previous and sum(len(current[color] ^ previous[color]) for color in COLORS) < 100:
                return None
            return current

        first = wait_for(lambda: next_frame('face-0', None), 'No filled polygon reached VGA')
        second = wait_for(lambda: next_frame('face-1', first), 'The filled polygon did not rotate')
        result['face_pixels'] = [{name: len(mask) for name, mask in frame.items()}
                                 for frame in (first, second)]
        result['changed_pixels'] = {name: len(first[name] ^ second[name]) for name in COLORS}
        guest.press('spc')
        if native:
            guest.wait('COMMAND OK\n', start=start)

        def cleared():
            guest.screenshot('after-key')
            current = masks(out / 'after-key.png', native)
            excess = {name: len(current[name] - baseline[name]) for name in COLORS}
            return excess if max(excess.values()) < 300 else None

        result['after_key_new_pixels'] = wait_for(cleared, 'The polygon was still visible after Space')
        if native:
            guest.command('6*7;')
            result['fresh_arithmetic'] = guest.result_pixels()
        return dict(result='pass', **result)
    except (RuntimeError, TimeoutError, ValueError) as error:
        return dict(result='fail', error=str(error), **result)
    finally:
        guest.close()


if __name__ == '__main__':
    compare = runpy.run_path('build/i386-demo-slider-v1/run.py')['main']
    compare(DEMO, capture, __doc__)
