import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('NoiseSleep.HC').read_bytes()
working = out/'working.img'
package = runpy.run_path('tools/package-i386-native-image.py')['package']
report = {'package': package(args.disk, working, additions={'/NoiseSleep.HC': fixture}),
          'fixture_sha256': hashlib.sha256(fixture).hexdigest()}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(working, out/'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/NoiseSleep.HC"', timeout=30)
    guest.wait('TTF timer after active noise ', 10)
    guest.command('6*7;')
    report.update(result='pass', after_sleep=guest.result_pixels())
except Exception as error:
    report.update(result='fail', error=str(error)[:3000])
    raise
finally:
    report['timer_trace'] = [line for line in guest.collect().splitlines()
                             if line.startswith(('TTF timer ', 'FAIL TTF '))]
    guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
