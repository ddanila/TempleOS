import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct
import time


parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
parser.add_argument('--irqchip', choices=('on','off'), default='on')
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('Probe.HC')
helper = Path('tools/test-i386-autocomplete-interaction.py').resolve()
packer = Path('tools/package-i386-native-image.py')
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
pins = {str(path):sha(path) for path in (args.disk, fixture, helper, packer, Path(__file__))}
report = {'result':'running', 'input_sha256':pins, 'kernel_irqchip':args.irqchip}
guest = None
try:
    image = out/'working.img'
    report['packaging'] = runpy.run_path(str(packer))['package'](
        args.disk, image, additions={'/SpeakerClockProbe.HC':fixture.read_bytes()})
    source = helper.read_text()
    needle = "'-machine','pc','-accel','kvm','-cpu','486,-fpu'"
    assert source.count(needle)==1
    source = source.replace(needle, f"'-machine','pc,kernel_irqchip={args.irqchip}','-accel','kvm','-cpu','486,-fpu'")
    namespace = {'__file__':str(helper), '__name__':'speaker_guest'}
    exec(compile(source,str(helper),'exec'), namespace)
    guest = namespace['Guest'](image, out/'guest', True)
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/SpeakerClockProbe.HC"')
    guest.type('SpeakerClockProbe;')
    guest.press('ret')
    log = guest.wait('SPEAKER JIFFIES ', 20)
    address = int(re.search(r'SPEAKER JIFFIES ([0-9A-F]+)\n',log)[1],16)
    samples = report['jiffies'] = []
    sample = out/'jiffies.bin'
    for _ in range(12):
        guest.call('pmemsave', val=address, size=8, filename=str(sample))
        samples.append(struct.unpack('<Q',sample.read_bytes())[0])
        time.sleep(.1)
    report['finished'] = 'SPEAKER finished\n' in guest.collect()
    if not report['finished'] or samples[-1] <= samples[0]:
        raise ValueError('Clock stalled during overlapping speaker effects')
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    if guest:
        guest.close()
    report['inputs_unchanged'] = all(sha(Path(name))==value for name,value in pins.items())
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
