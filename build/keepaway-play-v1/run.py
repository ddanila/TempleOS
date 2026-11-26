import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import time

from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path, nargs='?')
parser.add_argument('--out', type=Path, required=True)
parser.add_argument('--bundled-loader', action='store_true', help='Skip native library preloading')
parser.add_argument('--mouse', action='store_true', help='Jump with a physical right click')
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC').resolve()
guest_runner = Path('tools/test-i386-autocomplete-interaction.py')
reference = Path('tools/test-i386-timeclock-reference.py')
packer = Path('tools/package-i386-native-image.py')
inputs = [Path(__file__), fixture, guest_runner, reference, packer]
if args.disk:
    inputs.append(args.disk)

def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

pins = {str(path): sha(path) for path in inputs}
report = {'result': 'running', 'input_sha256': pins,
          'scope': 'Unchanged KeepAway instructions, jump, restart, exit and caller restoration'}
guest = None
try:
    if args.disk:
        image = out/'working.img'
        report['packaging'] = runpy.run_path(str(packer))['package'](
            args.disk, image, additions={'/KeepAwayProbe.HC': fixture.read_bytes()})
    else:
        overlay = out/'overlay'
        report['reference_sha256'] = runpy.run_path(str(reference))['restore_reference'](overlay)
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
            b'#include "T:/Apps/KeepAway/Load.HC"\n'
            + fixture.read_bytes() + b'\nKAProbe;\n')
        image = out/'original.iso'
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                        '--output', str(image)], check=True)
    Guest = runpy.run_path(str(guest_runner))['Guest']
    guest = Guest(image, out/'guest', bool(args.disk))
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        if not args.bundled_loader:
            guest.command('AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);')
            guest.command('AdamFile("C:/Adam/TaskSettings.HC",FALSE);')
        for command in (
            '#include "C:/Apps/KeepAway/Load.HC"',
            '#include "C:/KeepAwayProbe.HC"',
        ):
            guest.command(command)
        guest.type('KAProbe;')
        guest.press('ret')
    guest.wait('KEEP popup\n', 90)
    time.sleep(.5)
    guest.screenshot('instructions')
    guest.press('esc')
    guest.wait('KEEP playing\n', 30)
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        guest.screenshot('gameplay')
        with Image.open(guest.out / 'gameplay.png') as frame:
            pixels = Counter(frame.convert('RGB').get_flattened_data())
        yellow, red = pixels[(255, 255, 87)], pixels[(168, 0, 0)]
        if yellow >= 200_000 and red >= 1_000:
            report['arena_pixels'] = {'yellow': yellow, 'red': red}
            break
        if 'WINMGR window exception ' in guest.collect():
            raise ValueError('Window Manager exception during KeepAway')
        time.sleep(.2)
    else:
        raise TimeoutError('Missing KeepAway arena frame')
    if args.mouse:
        for down in (True, False):
            guest.call('input-send-event', events=[
                {'type': 'btn', 'data': {'down': down, 'button': 'right'}}])
            time.sleep(.1)
    else:
        guest.press('j')
    report['jump_input'] = 'right button' if args.mouse else 'j'
    guest.wait('KEEP jumped\n', 20)
    guest.press('ret')
    guest.wait('KEEP restarted\n', 20)
    guest.press('esc')
    guest.wait('KEEP returned\n', 20)
    if args.disk:
        guest.command('6*7;')
        report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(name)) == digest for name, digest in pins.items())
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
