import argparse
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
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC').resolve()
guest_runner = Path('tools/test-i386-autocomplete-interaction.py')
reference = Path('tools/test-i386-timeclock-reference.py')
packer = Path('tools/package-i386-native-image.py')
source = Path('Apps/KeepAway/KeepAway.HC')
inputs = [Path(__file__), fixture, source, guest_runner, reference, packer]
if args.disk:
    inputs.append(args.disk)

def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

pins = {str(path): sha(path) for path in inputs}
report = {'result': 'running', 'input_sha256': pins,
          'scope': 'KeepAway with width-correct QSortI64 slots, gameplay rendering and caller-state checks'}
guest = None
try:
    app = source.read_bytes()
    edits = (
        (b'  Obj *o_sort[OBJS_NUM],*o;', b'  I64 o_sort[OBJS_NUM];\n  Obj *o;'),
        (b'    o=o_sort[i]=&objs[i];', b'    o=&objs[i];\n    o_sort[i]=o(I64);'),
        (b'    DrawObj(dc,o_sort[i],tt);', b'    DrawObj(dc,o_sort[i](Obj *),tt);'),
    )
    for before, after in edits:
        if app.count(before) != 1:
            raise ValueError('KeepAway sort site changed')
        app = app.replace(before, after)
    report['patched_application_sha256'] = hashlib.sha256(app).hexdigest()
    if args.disk:
        image = out/'working.img'
        pack = runpy.run_path(str(packer))
        snapshot, package = pack['snapshot'], pack['package']
        original = snapshot(args.disk.read_bytes())[1]
        app_path = '/Apps/KeepAway/KeepAway.HC'
        if original[app_path][2] != source.read_bytes():
            raise ValueError('Integrated KeepAway differs from the source base')

        def patched_snapshot(disk):
            tree, files, directories = snapshot(disk)
            attr, date, _ = files[app_path]
            replacement = (attr, date, app)
            tree['Apps'][2]['KeepAway'][2]['KeepAway.HC'] = replacement
            files[app_path] = replacement
            return tree, files, directories

        package.__globals__['snapshot'] = patched_snapshot
        try:
            report['packaging'] = package(
                args.disk, image, additions={'/KeepAwayProbe.HC': fixture.read_bytes()})
        finally:
            package.__globals__['snapshot'] = snapshot
        delivered = snapshot(image.read_bytes())[1]
        changed = sorted(path for path in original if original[path] != delivered.get(path))
        if changed != [app_path] or delivered[app_path][2] != app:
            raise ValueError(f'Unexpected application changes: {changed}')
        report['changed_files'] = changed
    else:
        overlay = out/'overlay'
        report['reference_sha256'] = runpy.run_path(str(reference))['restore_reference'](overlay)
        (overlay/'KeepAwaySort.HC').write_bytes(app)
        (overlay/'Once.HC').write_bytes(
            b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
            b'#include "T:/KeepAwaySort.HC"\n'
            + fixture.read_bytes() + b'\nKAProbe;\n')
        image = out/'original.iso'
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                        '--output', str(image)], check=True)
    Guest = runpy.run_path(str(guest_runner))['Guest']
    guest = Guest(image, out/'guest', bool(args.disk))
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        for command in (
            'AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);',
            'AdamFile("C:/Adam/TaskSettings.HC",FALSE);',
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
    with Image.open(guest.out/'gameplay.png') as frame:
        colors = frame.convert('RGB')
        report['arena_yellow_pixels'] = sum(pixel == (255, 255, 87) for pixel in colors.get_flattened_data())
        report['border_red_pixels'] = sum(pixel == (168, 0, 0) for pixel in colors.get_flattened_data())
    log = guest.collect()
    if 'WINMGR window exception ' in log:
        raise ValueError('Window Manager exception during KeepAway workflow')
    if report['arena_yellow_pixels'] < 200_000 or report['border_red_pixels'] < 1_000:
        raise ValueError('Gameplay capture is missing the arena or its border')
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(name)) == digest for name, digest in pins.items())
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
