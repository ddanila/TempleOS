import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import subprocess
import sys
import tempfile
import time

from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('--disk', type=Path)
parser.add_argument('--reference-image', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir(parents=True)
fixture = Path(__file__).with_name('Probe.HC').read_bytes()
demo = Path('Demo/Graphics/BSpline.HC')
native = bool(args.disk)
sha = lambda data: hashlib.sha256(data).hexdigest()
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
if native:
    pack = runpy.run_path('tools/package-i386-native-image.py')
    assert pack['snapshot'](args.disk.read_bytes())[1]['/'+demo.as_posix()][2] == demo.read_bytes()
    image = out/'working.img'
    pack['package'](args.disk, image, additions={'/Probe/BSpline.HC': fixture})
elif args.reference_image:
    image = args.reference_image.resolve()
    receipt = json.loads((image.parent / 'result.json').read_text())
    assert receipt['input_sha256'] == sha(image.read_bytes())
    pinned = runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference']
    with tempfile.TemporaryDirectory(dir=out) as reference_tree:
        assert pinned(Path(reference_tree))[demo.as_posix()] == sha(demo.read_bytes())
else:
    overlay = out/'overlay'
    overlay.mkdir()
    pins = runpy.run_path('tools/test-i386-timeclock-reference.py')['restore_reference'](overlay)
    assert pins[demo.as_posix()] == sha(demo.read_bytes())
    (overlay/'Once.HC').write_bytes(fixture)
    image = out/'original.iso'
    subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),
                    '--output',str(image)],check=True)

guest = Guest(image,out/'guest',native,reference_cpus=1)
report = dict(result='running', demo_sha256=sha(demo.read_bytes()),
              input_sha256=sha(image.read_bytes()), mode='native' if native else 'original',
              scope='Unmodified BSpline demo with six physical control-point clicks, two closed curves, and key exit')

def pointer():
    found = re.findall(r'^COLOR PTR (\d+) (\d+)$',guest.collect(),re.M)
    if not found:
        raise ValueError('Missing pointer sample')
    return tuple(map(int,found[-1]))

def move_to(x,y):
    for _ in range(36):
        px,py = pointer()
        dx,dy = x-px,y-py
        if abs(dx)<=2 and abs(dy)<=2:
            return px,py
        events = [{'type':'rel','data':{'axis':axis,'value':max(-64,min(64,delta))}}
                  for axis,delta in [('x',dx),('y',dy)] if delta]
        guest.call('input-send-event',events=events)
        time.sleep(.11)
    raise ValueError(f'Unable to move to {(x,y)} from {pointer()}')

def button(name,down):
    guest.call('input-send-event',events=[{'type':'btn','data':{'button':name,'down':down}}])
    time.sleep(.15)

def picture(name):
    guest.screenshot(name)
    with Image.open(guest.out / (name + '.png')) as frame:
        return frame.convert('RGB')

def color_pixels(frame, color):
    canvas = frame.crop((25, 90, 306, 390))
    return sum(pixel == color for pixel in canvas.get_flattened_data())

try:
    if native:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/BSpline.HC"')
        guest.command('CTask *bw=Spawn(&PalWatch,NULL,"BSpline pointer",,Fs);')
    else:
        guest.wait('DOODLE READY\n')
        time.sleep(2)
        guest.type('CTask *bw=Spawn(&PalWatch,NULL,"BSpline pointer",,Fs);')
        guest.press('ret')
    guest.wait('COLOR PTR ')
    offset = len(guest.collect())
    drive = 'C' if native else 'T'
    command = f'ExeFile("{drive}:/{demo}");'
    if not native:
        command += r'PalLog("BSPLINE DONE\n");'
    guest.type(command)
    guest.press('ret')
    time.sleep(3)
    output = guest.collect()[offset:]
    if 'INPUT REJECT ' in output:
        raise ValueError(output)
    move_to(292, 420)
    start = picture('start')
    report['points'] = []
    green = (0, 168, 0)
    prior = color_pixels(start, green)
    for point in [(70, 165), (165, 115), (266, 170),
                  (263, 309), (164, 355), (65, 305)]:
        report['points'].append(move_to(*point))
        button('left', True)
        button('left', False)
        deadline = time.monotonic() + 4
        while time.monotonic() < deadline:
            controls = picture('controls')
            count = color_pixels(controls, green)
            if count > prior:
                break
            time.sleep(.15)
        else:
            raise ValueError(f'Control point {point} did not draw a green circle')
        prior = count
    move_to(292, 420)
    controls = picture('controls')
    report['green_pixels'] = color_pixels(controls, green)
    button('right', True)
    button('right', False)
    time.sleep(2)
    curves = picture('curves')
    for name, color in [('red', (168, 0, 0)), ('blue', (0, 0, 168))]:
        report[name + '_pixels'] = count = color_pixels(curves, color)
        assert count > 150 and color_pixels(controls, color) == 0, name
    guest.press('spc')
    guest.wait('COMMAND OK\n' if native else 'BSPLINE DONE\n', 25, offset)
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        cleared = picture('cleared')
        if not any(color_pixels(cleared, color)
                   for color in (green, (168, 0, 0), (0, 0, 168))):
            break
        time.sleep(.15)
    else:
        raise ValueError('Graphics remained on screen after exiting the demo')
    if native:
        guest.command('Kill(bw);')
        guest.command('6*7;')
        report['fresh_arithmetic'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
