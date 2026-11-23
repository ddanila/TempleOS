import argparse
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
original = Path('Apps/Span/SpanMain.HC').read_bytes()
draw = original[original.index(b'U0 DrawSpring('):original.index(b'U0 PlaceSpring(')]
types = b"""class SpringTestMode {I64 state;} mode_bttn;
class SpringTestMass {F64 x,y;};
#define MD_CONCRETE 1
#define MD_STEEL 2
#define MD_WIRE 3
"""
draw = draw.replace(b'MyMass *tmpm', b'SpringTestMass *tmpm')
without_line = re.sub(rb'^  GrLine3.*\n', b'', draw, flags=re.M)
without_switch = re.sub(rb'^  switch .*?^  }\n', b'', draw, flags=re.M | re.S)
constants = draw.replace(b'MD_CONCRETE', b'1').replace(b'MD_STEEL', b'2').replace(b'MD_WIRE', b'3')
cases = {
    'SwitchOnly': without_line, 'LineOnly': without_switch,
    'LiteralLabels': constants, 'Both': draw,
}
files = {'/SpringProbeTypes.HH': types}
files.update({'/' + name + '.HC': body.replace(b'DrawSpring', name.encode())
              for name, body in cases.items()})
package = runpy.run_path('tools/package-i386-native-image.py')['package']
image = out / 'working.img'
report = {'result':'running', 'packaging': package(args.disk, image, additions=files),
          'cases': {}}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out / 'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/SpringProbeTypes.HH"')
    for name in cases:
        try:
            guest.command('#include "C:/' + name + '.HC"', 45)
            report['cases'][name] = {'result':'pass'}
        except ValueError as exc:
            report['cases'][name] = {'result':'fail', 'error':str(exc)}
            # Let the failed command finish unwinding before typing again.
            guest.wait('COMMAND ERROR\n', 10, guest.collect().rfind('INPUT LINE '))
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report,indent=2)+'\n')
