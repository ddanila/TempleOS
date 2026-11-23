import argparse
import hashlib
import json
from pathlib import Path
import runpy
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
loader = fixture.with_name('Load.HC')
inputs = [Path(__file__), fixture, loader, guest_runner, reference, packer]
if args.disk:
    inputs.append(args.disk)

def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

pins = {str(path): sha(path) for path in inputs}
report = {'result': 'running', 'input_sha256': pins,
          'scope': 'KeepAway launch with on-demand libraries, jump, restart, exit and caller restoration'}
guest = None
try:
    if args.disk:
        image = out/'working.img'
        pack = runpy.run_path(str(packer))
        snapshot, package = pack['snapshot'], pack['package']
        app_path = '/Apps/KeepAway/Load.HC'

        def patched_snapshot(disk):
            tree, files, directories = snapshot(disk)
            attr, date, _ = files[app_path]
            replacement = (attr, date, loader.read_bytes())
            tree['Apps'][2]['KeepAway'][2]['Load.HC'] = replacement
            files[app_path] = replacement
            return tree, files, directories

        package.__globals__['snapshot'] = patched_snapshot
        try:
            report['packaging'] = package(
                args.disk, image, additions={'/KeepAwayProbe.HC': fixture.read_bytes()})
        finally:
            package.__globals__['snapshot'] = snapshot
        original = snapshot(args.disk.read_bytes())[1]
        delivered = snapshot(image.read_bytes())[1]
        if sorted(name for name in original if original[name] != delivered.get(name)) != [app_path]:
            raise ValueError('Unexpected modified files')
    else:
        overlay = out/'overlay'
        report['reference_sha256'] = runpy.run_path(str(reference))['restore_reference'](overlay)
        (overlay/'Apps/KeepAway/Load.HC').write_bytes(loader.read_bytes())
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
