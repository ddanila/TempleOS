import argparse
import hashlib
import json
from pathlib import Path
import runpy


parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
reference = Path('tests/guest/i386-logic-reference/Once.HC')
guest_runner = Path('tools/test-i386-autocomplete-interaction.py')
packer = Path('tools/package-i386-native-image.py')
report = {'result': 'running', 'scope': 'Original ten-case Logic synthesis oracle on native i386'}
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
inputs = (args.disk, reference, guest_runner, packer, Path(__file__))
pins = {str(path): sha(path) for path in inputs}
report['input_sha256'] = pins
fixture = reference.read_bytes()
include = b'#include "T:/Apps/Logic/Load.HC"\n'
assert fixture.count(include) == 1
fixture = fixture.replace(include, b'')
source = args.out / 'working.img'
guest = None
try:
    pack = runpy.run_path(str(packer))
    report['packaging'] = pack['package'](args.disk, source, additions={'/LogicOracle.HC': fixture})
    files = pack['snapshot'](source.read_bytes())[1]
    inventory = json.loads(Path('docs/i386-compatibility-inventory.json').read_text())
    app_hashes = {}
    for entry in inventory['entries']:
        name = entry['path']
        if name.startswith('Apps/Logic/'):
            digest = hashlib.sha256(files['/' + name][2]).hexdigest()
            if digest != entry['reference_sha256']:
                raise ValueError(f'Logic source mismatch: {name}')
            app_hashes[name] = digest
    report['application_sha256'] = app_hashes
    Guest = runpy.run_path(str(guest_runner))['Guest']
    guest = Guest(source.resolve(), args.out.resolve() / 'guest', True)
    guest.wait('DONE native kernel startup\n')
    for command in (
        'AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);',
        'AdamFile("C:/Adam/TaskSettings.HC",FALSE);',
        '#include "C:/Apps/Logic/Load.HC"',
        '#include "C:/LogicOracle.HC"',
    ):
        guest.command(command)
    guest.wait('LOGIC MASK 1023\n', 30)
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report.update(result='pass', mask=1023)
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(name)) == digest for name, digest in pins.items())
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
