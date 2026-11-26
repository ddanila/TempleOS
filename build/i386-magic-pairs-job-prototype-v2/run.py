"""Check the unchanged MagicPairs demo through the native queue prototype."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('image', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
here = Path(__file__).resolve().parent
batch = runpy.run_path('tools/test-i386-demo-batch.py')
body = (batch['FIXTURE'] + '\nDemoBatchRun("C:/Demo/MagicPairs.HC","demo-0.DD");\n'
        'DemoBatchLog("DEMO BATCH DONE\\n");\n').encode()
files = {'/Probe/Jobs.HC': (here/'Jobs.HC').read_bytes(),
         '/Probe/JobContract.HC': (here/'Contract.HC').read_bytes(),
         '/Probe/MagicPairs.HC': body}
pack = runpy.run_path('tools/package-i386-native-image.py')
working = args.out/'working.img'
report = {'result': 'running', 'packaging': pack['package'](args.image, working, additions=files)}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(working, args.out/'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    for command in ('#include "C:/Probe/Jobs.HC"', '#include "C:/Probe/JobContract.HC"'):
        guest.command(command)
    guest.command('#include "C:/Probe/MagicPairs.HC"', timeout=600)
    guest.wait('DEMO BATCH DONE\n')
    compare = runpy.run_path('build/i386-demo-magic-pairs-v1/compare.py')
    report['document'] = compare['read_document'](guest.out/'demo-0.DD', compare['expected_pairs']())
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as error:
    report.update(result='fail', error=str(error))
    raise
finally:
    guest.close()
    report['inputs_unchanged'] = (
        hashlib.sha256(args.image.read_bytes()).hexdigest() == report['packaging']['source_sha256'])
    (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
