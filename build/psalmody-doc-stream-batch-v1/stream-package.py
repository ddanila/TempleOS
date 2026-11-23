import hashlib
import json
from pathlib import Path
import runpy
import sys

source = Path(sys.argv[1]).resolve()
out = Path(sys.argv[2]).resolve()
out.mkdir()
contract = Path('tools/test-i386-doc-stream.py')
packer = Path('tools/package-i386-native-image.py')
guest_runner = Path('tools/test-i386-autocomplete-interaction.py')
commands = runpy.run_path(str(contract))['COMMANDS']
declarations = [row[0] for row in commands[:3]]
body = []
checks = 0
for statement, expected in commands[3:-1]:
    if expected:
        assert expected==['1'] and statement.endswith(';')
        checks += 1
        body.append(f"if(!({statement[:-1]}))throw('Stream{checks}',TRUE);")
    else:
        body.append(statement)
fixture = ('\n'.join(declarations)+'\nU0 StreamCheck()\n{\n  '+
           '\n  '.join(body)+'\n}\n').encode()
(out/'StreamCheck.HC').write_bytes(fixture)
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
pins = {str(p):sha(p) for p in (source,contract,packer,guest_runner,Path(__file__))}
report = dict(result='running',input_sha256=pins,checks=checks)
guest = None
try:
    path='/Probe/StreamCheck.HC'
    pack = runpy.run_path(str(packer))
    before = pack['snapshot'](source.read_bytes())[1]
    image = out/'working.img'
    pack['package'](source,image,additions={path:fixture})
    Guest = runpy.run_path(str(guest_runner))['Guest']
    guest = Guest(image,out/'guest',True)
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/Probe/StreamCheck.HC"')
    guest.command('StreamCheck;')
    guest.command('6*7;')
    report['fresh_result']=guest.result_pixels()
    guest.close()
    guest=None
    after = pack['snapshot'](image.read_bytes())[1]
    assert after.keys() == before.keys() | {path} and after[path][2] == fixture
    assert all(after[name] == payload for name,payload in before.items())
    report.update(result='pass',added_fixture_sha256=sha(out/'StreamCheck.HC'))
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in pins.items())
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
