import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC').read_bytes()
report = {'result': 'running', 'fixture_sha256': hashlib.sha256(fixture).hexdigest()}
if args.disk:
    doc_types = Path('Kernel/DocTypes.HH').read_bytes()
    start = doc_types.index(b'class CEdFileName\n')
    chooser_type = doc_types[start:doc_types.index(b'\n};', start)+4]
    doc_popup = Path('Adam/DolDoc/DocPopUp.HC').read_bytes()
    chooser = chooser_type + b'\n\n' + doc_popup[doc_popup.index(b'public U8 *FileNameForm'):
                                                doc_popup.index(b'#help_index "DolDoc"\n')]
    image = out / 'working.img'
    packer = runpy.run_path('tools/package-i386-native-image.py')
    report['package'] = packer['package'](args.disk, image, additions={
        '/FileNameChooser.HC': chooser, '/FileNameProbe.HC': fixture,
    })
else:
    overlay = out / 'overlay'
    reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
    refs = reference['restore_reference'](overlay)
    report['chooser_reference_sha256'] = refs['Adam/DolDoc/DocPopUp.HC']
    (overlay / 'Once.HC').write_bytes(
        b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
        + fixture + b'\nFNProbe;\n')
    image = out / 'original.iso'
    subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                    '--output', str(image)], check=True)
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out / 'guest', bool(args.disk))
try:
    if args.disk:
        guest.wait('DONE native kernel startup\n')
        guest.command('#include "C:/FileNameChooser.HC"')
        guest.command('#include "C:/FileNameProbe.HC"')
        guest.type('FNProbe;')
        guest.press('ret')
    guest.wait('FILENAME accept\n', 90)
    time.sleep(2)
    guest.screenshot('accept')
    guest.press('esc')
    guest.wait('FILENAME returned C:/Default.DATA\n',20)
    guest.wait('FILENAME cancel\n',20)
    time.sleep(2)
    guest.screenshot('cancel')
    guest.key('shift', True)
    guest.press('esc')
    guest.key('shift', False)
    log = guest.wait('FILENAME done\n',20)
    if 'FAIL filename' in log:
        raise ValueError('Filename or popup state mismatch')
    if args.disk:
        guest.command('6*7;')
        report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    report['observations'] = [line for line in guest.collect().splitlines()
                              if line.startswith(('FILENAME ', 'FAIL filename'))]
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
