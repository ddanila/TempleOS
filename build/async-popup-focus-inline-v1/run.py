import argparse
import hashlib
import json
from pathlib import Path
import runpy
import re
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path, nargs='?')
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
          'scope': 'Asynchronous PopUp View retirement and caller keyboard focus'}
guest = None
try:
    if args.disk:
        image = out/'working.img'
        report['packaging'] = runpy.run_path(str(packer))['package'](
            args.disk, image, additions={'/PopupProbe.HC': fixture.read_bytes()})
    else:
        overlay = out/'overlay'
        report['reference_sha256'] = runpy.run_path(str(reference))['restore_reference'](overlay)
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
            + fixture.read_bytes() + b'\nPAProbe;\n')
        image = out/'original.iso'
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                        '--output', str(image)], check=True)
    Guest = runpy.run_path(str(guest_runner))['Guest']
    guest = Guest(image, out/'guest', bool(args.disk))
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        for command in (
            '#include "C:/PopupProbe.HC"',
        ):
            guest.command(command)
        guest.type('PAProbe;')
        guest.press('ret')
    log = guest.wait('POPUP view ready\n', 45)
    match = re.search(r'POPUP state ([0-9A-F]+) ([0-9A-F]+) ([0-9A-F]+)\n', log)
    if not match:
        log = guest.wait('POPUP state ', 15)
        match = re.search(r'POPUP state ([0-9A-F]+) ([0-9A-F]+) ([0-9A-F]+)\n', log)
    owner, child, slot = (int(value, 16) for value in match.groups())
    report['owner'] = owner
    report['child'] = child
    sample = out/'focus.bin'

    def focused():
        guest.call('pmemsave', val=slot, size=4 if args.disk else 8, filename=str(sample))
        return int.from_bytes(sample.read_bytes(),'little')

    time.sleep(.8)
    report['focus_before_escape'] = focused()
    guest.screenshot('popup')
    guest.press('esc')
    guest.wait('POPUP view returned\n', 20)
    guest.wait('POPUP retired focus=', 20)
    time.sleep(.6)
    report['focus_after_retirement'] = focused()
    guest.press('q')
    guest.wait('POPUP caller key\n', 20)
    if report['focus_before_escape'] != child or report['focus_after_retirement'] != owner:
        raise ValueError('Popup focus handoff differs from the original caller expectation')
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
