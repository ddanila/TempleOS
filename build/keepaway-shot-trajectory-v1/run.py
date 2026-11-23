import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path, nargs='?')
parser.add_argument('--mouse', action='store_true')
parser.add_argument('--out', type=Path, required=True)
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
          'scope': 'KeepAway scoring with controlled ball placement, physical shot input, and caller recovery'}
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
    time.sleep(.5)
    guest.screenshot('gameplay')
    guest.press('j')
    guest.wait('KEEP jumped\n', 20)
    guest.press('ret')
    guest.wait('KEEP restarted\n', 20)
    guest.wait('KEEP handoff score 2\n', 20)
    guest.wait('KEEP pass score 8\n', 20)
    if args.mouse:
        for down in (True, False):
            guest.call('input-send-event', events=[
                {'type': 'btn', 'data': {'down': down, 'button': 'left'}}])
            time.sleep(.1)
    else:
        guest.press('spc')
    guest.wait('KEEP shot trajectory\n', 20)
    report['shot_input'] = 'left button' if args.mouse else 'space'
    report['observed_scores'] = [2, 8]
    guest.press('esc')
    guest.wait('KEEP returned\n', 20)
    if args.disk:
        guest.command('6*7;')
        report['fresh_result'] = guest.result_pixels()
    if 'FAIL KeepAway' in guest.collect() or 'WINMGR window exception ' in guest.collect():
        raise ValueError('KeepAway reported a gameplay failure')
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(name)) == digest for name, digest in pins.items())
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
