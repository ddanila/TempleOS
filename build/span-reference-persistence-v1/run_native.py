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
root = Path(__file__).resolve().parent
fixture = (root / 'Probe.HC').read_bytes().replace(b'B:/SpanProbe.DATA', b'C:/SpanProbe.DATA')
expected = (root / 'ram-reference/steel-bridge.data').read_bytes()
source = Path('Kernel/KernelA.HH').read_bytes()
types = source[source.index(b'#help_index "Math/ODE"'):source.index(b'#help_index "Processor"')]
serial = Path('build/strut-rk4-derivative-v1/SerialODE.HC').read_bytes()
scalar = Path('build/strut-ode-power-v1/D3.HC').read_bytes()
packer = runpy.run_path('tools/package-i386-native-image.py')
image = out / 'working.img'
report = {'result': 'running', 'expected_sha256': hashlib.sha256(expected).hexdigest()}
report['package'] = packer['package'](args.disk, image, additions={
    '/SpanProbe.HC': fixture, '/SpanODETypes.HH': types, '/SpanODESerial.HC': serial,
    '/SpanODEScalar.HC': scalar,
})
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out / 'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    for command in (
        '#include "C:/SpanODETypes.HH"',
        '#include "C:/SpanODEScalar.HC"',
        '#include "C:/SpanODESerial.HC"',
        'AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);',
        'AdamFile("C:/Adam/TaskSettings.HC",FALSE);',
        '#include "C:/Adam/Ctrls/CtrlsBttn.HC"',
        '#include "C:/Apps/Span/Load.HC"',
        '#include "C:/SpanProbe.HC"',
    ):
        report['command'] = command
        guest.command(command)
    guest.type('SpanProbe;')
    guest.press('ret')
    guest.wait('SPAN returned\n',120)
    captured = (out / 'guest/steel-bridge.data').read_bytes()
    report['capture_size'] = len(captured)
    report['capture_sha256'] = hashlib.sha256(captured).hexdigest()
    if captured != expected:
        raise ValueError('Native Span bridge bytes differ from the pinned original')
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
