import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
overlay = out / 'overlay'
fixture = Path(__file__).with_name('Probe.HC')
reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
sources = reference['restore_reference'](overlay)
(overlay / 'Once.HC').write_bytes(
    b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
    b'#include "T:/Apps/Span/Load.HC"\n' + fixture.read_bytes() + b'\nSPProbe;\n')
image = out / 'original.iso'
subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(overlay),
                '--output', str(image)], check=True)
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
report = {'result': 'running', 'image_sha256': sha(image), 'fixture_sha256':sha(fixture),
          'application_source_sha256': {name: digest for name, digest in sources.items()
                                        if name.startswith('Apps/Span/')}}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out / 'guest', False)
try:
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
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail', error=str(exc))
    raise
finally:
    report['observations'] = [line for line in guest.collect().splitlines()
                              if line.startswith(('SPAN ', 'FAIL Span'))]
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
