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
demo = Path('Demo/Graphics/Symmetry.HC')
native = bool(args.disk)
sha = lambda data: hashlib.sha256(data).hexdigest()
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
if native:
    pack = runpy.run_path('tools/package-i386-native-image.py')
    assert pack['snapshot'](args.disk.read_bytes())[1]['/'+demo.as_posix()][2] == demo.read_bytes()
    image = out/'working.img'
    pack['package'](args.disk, image, additions={'/Probe/Symmetry.HC': fixture})
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
              scope='Unmodified Symmetry demo with default and mouse-defined symmetry axes and Escape')

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

def ink(frame, box):
    return sum(pixel == (0, 0, 0)
               for pixel in frame.crop(box).get_flattened_data())


def drag(name, start, end):
    first = move_to(*start)
    button(name, True)
    try:
        last = move_to(*end)
    finally:
        button(name, False)
    return [first, last]


try:
    if native:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/Probe/Symmetry.HC"')
        guest.command('CTask *sw=Spawn(&PalWatch,NULL,"Symmetry pointer",,Fs);')
    else:
        guest.wait('DOODLE READY\n')
        time.sleep(2)
        guest.type('CTask *sw=Spawn(&PalWatch,NULL,"Symmetry pointer",,Fs);')
        guest.press('ret')
    guest.wait('COLOR PTR ')
    offset = len(guest.collect())
    drive = 'C' if native else 'T'
    command = f'ExeFile("{drive}:/{demo}");'
    if not native:
        command += r'PalLog("SYMMETRY DONE\n");'
    guest.type(command)
    guest.press('ret')
    time.sleep(3)
    output = guest.collect()[offset:]
    if 'INPUT REJECT ' in output:
        raise ValueError(output)
    move_to(270, 400)
    first_boxes = [(100, 145, 205, 210), (420, 145, 545, 210)]
    second_boxes = [(210, 273, 318, 330), (462, 273, 590, 330)]
    before = picture('start')
    assert not any(ink(before, box) for box in first_boxes + second_boxes)
    report['first_drag'] = drag('left', (115, 164), (185, 185))
    move_to(270, 400)
    first = picture('first')
    report['first_ink'] = [ink(first, box) for box in first_boxes]
    assert min(report['first_ink']) >= 50, report['first_ink']
    report['axis_drag'] = drag('right', (392, 120), (392, 380))
    report['second_drag'] = drag('left', (226, 290), (300, 311))
    move_to(270, 400)
    second = picture('second')
    report['second_ink'] = [ink(second, box) for box in second_boxes]
    assert min(report['second_ink']) >= 50, report['second_ink']
    guest.press('esc')
    guest.wait('COMMAND OK\n' if native else 'SYMMETRY DONE\n', 25, offset)
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        cleared = picture('cleared')
        if not any(ink(cleared, box) for box in first_boxes + second_boxes):
            break
        time.sleep(.15)
    else:
        raise ValueError('Symmetry drawing remained after exit')
    if native:
        guest.command('Kill(sw);')
        guest.command('6*7;')
        report['fresh_arithmetic'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
