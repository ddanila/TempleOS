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
source = Path('Kernel/KernelA.HH')
tree = Path('Adam/AMathODE.HC')
serial = Path(__file__).with_name('SerialODE.HC')
vector = Path('build/strut-ode-power-v1/D3.HC')
fixture = Path(__file__).with_name('Probe.HC')
helper = Path('tools/test-i386-autocomplete-interaction.py')
packer = Path('tools/package-i386-native-image.py')
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
pins = {str(path): sha(path) for path in (args.disk,source,tree,serial,vector,fixture,helper,packer,Path(__file__))}
report = {'result':'running','input_sha256':pins,'scope':'Scalar D3 and the native single-CPU ODE variant against analytic values'}
body = source.read_bytes()
types = body[body.index(b'#help_index "Math/ODE"'):body.index(b'#help_index "Processor"')]
report['type_slice_sha256'] = hashlib.sha256(types).hexdigest()
guest = None
try:
    image = out/'working.img'
    pack = runpy.run_path(str(packer))
    report['packaging'] = pack['package'](args.disk,image,additions={'/Probe/ODETypes.HH':types,'/Probe/SerialODE.HC':serial.read_bytes(),'/Probe/D3.HC':vector.read_bytes(),'/Probe/ODEProbe.HC':fixture.read_bytes()})
    files = pack['snapshot'](image.read_bytes())[1]
    assert files['/Adam/AMathODE.HC'][2] == tree.read_bytes()
    app_hashes = {}
    for name in ('Load.HC','Run.HC','Strut.HC'):
        path = 'Apps/Strut/' + name
        assert files['/'+path][2] == Path(path).read_bytes()
        app_hashes[path] = sha(Path(path))
    report['application_sha256'] = app_hashes
    Guest = runpy.run_path(str(helper))['Guest']
    guest = Guest(image,out/'guest',True)
    guest.wait('DONE native kernel startup\n')
    report['stages'] = {}
    for stage, command in (
        ('types','#include "C:/Probe/ODETypes.HH"'),
        ('d3','#include "C:/Probe/D3.HC"'),
        ('ode','#include "C:/Probe/SerialODE.HC"'),
        ('probe','#include "C:/Probe/ODEProbe.HC"'),
        ('numeric','ODEProbe;'),
    ):
        report['stage'] = stage
        start = len(guest.collect())
        guest.command(command)
        log = guest.collect()[start:]
        if 'INPUT REJECT ' in log or 'FRONTEND ERROR' in log:
            raise ValueError(log[-700:])
        report['stages'][stage] = 'pass'
    guest.wait('ODE mask 7\n',20)
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(path)) == digest for path,digest in pins.items())
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
