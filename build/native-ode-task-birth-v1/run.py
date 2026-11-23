import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC')
packer = Path('tools/package-i386-native-image.py')
helper = Path('tools/test-i386-autocomplete-interaction.py')
inputs = [args.disk, fixture, packer, helper, Path(__file__)]


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


pins = {str(path): sha(path) for path in inputs}
report = {'result': 'running', 'input_sha256': pins, 'rings': {}}
guest = None
try:
    image = out / 'probe.img'
    package = runpy.run_path(str(packer))['package']
    report['package'] = package(
        args.disk, image, additions={'/ODERingProbe.HC': fixture.read_bytes()})
    Guest = runpy.run_path(str(helper))['Guest']
    guest = Guest(image, out / 'guest', True)
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/ODERingProbe.HC"')
    guest.command('ODERingProbe;')
    timings = re.findall(r'^ODE RING (console|spawn) ([0-9A-F]+) ([0-9A-F]+) ([0-9A-F]+)$',
                        guest.collect(), re.M)
    for label, head, next_link, last_link in timings:
        report['rings'][label] = {
            'head': head, 'next': next_link, 'last': last_link
        }
    if set(report['rings']) != {'console', 'spawn'}:
        raise ValueError('Missing console or spawned task ring observation')
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    if any(ring['next'] != ring['head'] or ring['last'] != ring['head']
           for ring in report['rings'].values()):
        raise ValueError('Expected a self-linked empty ODE ring in both tasks')
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged'] = all(sha(path) == pins[str(path)] for path in inputs)
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
