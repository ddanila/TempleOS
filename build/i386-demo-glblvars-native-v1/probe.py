"""Launch the bundled GlblVars source from the native desktop prompt."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('image', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
working = args.out / 'working.img'
shutil.copyfile(args.image, working)
digest = sha(args.image)
snapshot = runpy.run_path('tools/package-i386-native-image.py')['snapshot']
source = snapshot(working.read_bytes())[1]['/Demo/GlblVars.HC'][2]
if source != Path('Demo/GlblVars.HC').read_bytes():
    raise ValueError('Delivered demo differs from the repository source')
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(working.resolve(), (args.out / 'guest').resolve(), True)
report = dict(result='running', image_sha256=digest,
              source_sha256=hashlib.sha256(source).hexdigest())
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('ExeFile("C:/Demo/GlblVars.HC");')
    guest.screenshot('demo-output')
    guest.command('6*7;')
    report.update(result='pass', fresh_result=guest.result_pixels())
except (TimeoutError, ValueError) as error:
    report.update(result='fail', error=str(error))
finally:
    guest.close()
    report['inputs_unchanged'] = sha(args.image) == digest
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
if report['result'] != 'pass' or not report['inputs_unchanged']:
    raise SystemExit('GlblVars prompt run failed; see result.json')
