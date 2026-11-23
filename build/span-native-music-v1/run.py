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
root = Path('build/span-reference-persistence-v1')
fixture = (root / 'Probe.HC').read_bytes().replace(b'B:/SpanProbe.DATA', b'C:/SpanProbe.DATA')
expected = (root / 'ram-reference/steel-bridge.data').read_bytes()
source = Path('Kernel/KernelA.HH').read_bytes()
types = source[source.index(b'#help_index "Math/ODE"'):source.index(b'#help_index "Processor"')]
serial = Path('build/strut-rk4-derivative-v1/SerialODE.HC').read_bytes()
scalar = Path('build/strut-ode-power-v1/D3.HC').read_bytes()
doc_types = Path('Kernel/DocTypes.HH').read_bytes()
start = doc_types.index(b'class CEdFileName\n')
chooser_type = doc_types[start:doc_types.index(b'\n};', start)+4]
doc_popup = Path('Adam/DolDoc/DocPopUp.HC').read_bytes()
chooser_functions = doc_popup[doc_popup.index(b'public U8 *FileNameForm'):
                              doc_popup.index(b'#help_index "DolDoc"\n')]
chooser = chooser_type + b'\n\n' + chooser_functions

source = Path('Adam/Snd/SndMusic.HC').read_bytes()
play = source[source.index(b'U8 *MusicSetOctave'):source.index(b'U0 MusicSettingsRst')]
assert play.count(b'cnts.jiffies') == 1
play = play.replace(b'cnts.jiffies', b'ToI64(Round(tS*1000.0))')
play = play.replace(b'ONA_REST', b'(-128)')
music = b'public U0 SndTaskEndCB() { Snd; Exit; }\n' + play
packer = runpy.run_path('tools/package-i386-native-image.py')
image = out / 'working.img'
report = {'result': 'running', 'expected_sha256': hashlib.sha256(expected).hexdigest()}
report['package'] = packer['package'](args.disk, image, additions={
    '/SpanProbe.HC': fixture, '/SpanODETypes.HH': types, '/SpanODESerial.HC': serial,
    '/SpanODEScalar.HC': scalar, '/SpanFileChooser.HC': chooser, '/SpanMusic.HC': music,
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
        '#include "C:/SpanFileChooser.HC"',
        '#include "C:/SpanMusic.HC"',
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
