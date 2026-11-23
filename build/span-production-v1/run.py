import argparse
import json
from pathlib import Path
import re
import runpy
import struct
import time

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC')
image = out / 'working.img'
package = runpy.run_path('tools/package-i386-native-image.py')['package']
report = {'result':'running','package':package(args.disk,image,additions={
    '/SpanProbe.HC':fixture.read_bytes(),
})}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out / 'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    for command in (
        '#include "C:/Apps/Span/Load.HC"',
        '#include "C:/SpanProbe.HC"',
    ):
        report['command']=command
        guest.command(command)
    guest.type('SPProbe;')
    guest.press('ret')
    log = guest.wait('SPAN instructions ', 90)
    address = int(re.search(r'SPAN instructions ([0-9A-F]+)\n',log)[1],16)
    pointer = out / 'pointer.bin'

    def click(target):
        for _ in range(50):
            guest.call('pmemsave', val=address, size=16, filename=str(pointer))
            x, y = struct.unpack('<2q', pointer.read_bytes())
            if (x, y) == target:
                break
            guest.call('input-send-event', events=[
                {'type':'rel','data':{'axis':'x','value':target[0]-x}},
                {'type':'rel','data':{'axis':'y','value':target[1]-y}},
            ])
            time.sleep(.2)
        else:
            raise ValueError(f'Mouse could not reach {target}')
        for down in (True, False):
            guest.call('input-send-event', events=[
                {'type':'btn','data':{'down':down,'button':'left'}},
            ])
            time.sleep(.3)

    guest.screenshot('instructions')
    click((128,278))
    guest.wait('SPAN editor ', 30)
    click((260,135))
    guest.wait('SPAN placed mass\n', 20)
    guest.screenshot('edited')
    guest.press('spc')
    guest.wait('SPAN simulation advanced\n', 25)
    guest.press('spc')
    guest.wait('SPAN stopped\n', 20)
    guest.key('shift', True)
    guest.press('esc')
    guest.key('shift', False)
    log = guest.wait('SPAN returned\n', 30)
    if 'FAIL Span' in log:
        raise ValueError('Span fixture reported a state or cleanup failure')
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    report['observations'] = [line for line in guest.collect().splitlines()
                              if line.startswith(('SPAN ', 'FAIL Span'))]
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
