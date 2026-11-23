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
line = re.sub(rb'^  switch .*?^  }\n', b'', draw, flags=re.M | re.S)
call = b'  GrLine3(dc,tmpm->x,tmpm->y,0,x,y,0);'
assert line.count(call) == 1
types += b"U0 LocalLine(CDC *dc,I64 x1,I64 y1,I64 z1,I64 x2,I64 y2,I64 z2) {}\n"
cases = {
    'Implicit': line,
    'TypedLocals': line.replace(call,
        b'  I64 x1=tmpm->x,y1=tmpm->y;\n  GrLine3(dc,x1,y1,0,x,y,0);'),
    'IntegerMembers': line.replace(call,
        b'  GrLine3(dc,1,2,0,x,y,0);'),
    'IntegerEnds': line.replace(call,
        b'  GrLine3(dc,tmpm->x,tmpm->y,0,1,2,0);'),
    'LocalCall': line.replace(b'GrLine3',b'LocalLine'),
}
cases['Runtime'] = b"""
I64 SpringCoordinates(I64 x,I64 y)
{ return 100*x+y; }
U0 SpringConversionProbe()
{
  SpringTestMass mass;
  U8 *text;
  mass.x=7.75;
  mass.y=-3.5;
  if(SpringCoordinates(mass.x,mass.y)==697)
    text="F64 converted 697\\n";
  else
    text="FAIL F64 argument conversion\\n";
  while(*text) OutU8(0xE9,*text++);
}
"""
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
    guest.command('SpringConversionProbe;')
    guest.wait('F64 converted 697\n',10)
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report,indent=2)+'\n')
