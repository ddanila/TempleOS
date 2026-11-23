import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import time

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('--sample-stall', action='store_true')
parser.add_argument('--userspace-irqchip', action='store_true')
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('NoiseSleep.HC').read_bytes()
working = out/'working.img'
package = runpy.run_path('tools/package-i386-native-image.py')['package']
report = {'package': package(args.disk, working, additions={'/NoiseSleep.HC': fixture}),
          'fixture_sha256': hashlib.sha256(fixture).hexdigest()}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
machine = 'pc,kernel-irqchip=off' if args.userspace_irqchip else 'pc'
report['machine'] = machine
guest = Guest(working, out/'guest', True, native_machine=machine)
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/NoiseSleep.HC"', timeout=30)
    guest.wait('TTF timer after active noise ', 10)
    guest.command('6*7;')
    report.update(result='pass', after_sleep=guest.result_pixels())
except Exception as error:
    report.update(result='fail', error=str(error)[:3000])
    if args.sample_stall:
        match = re.search(r'TTF timer address ([0-9A-F]+)', guest.collect())
        samples = []
        for _ in range(3):
            sample = {'registers': guest.call('human-monitor-command',
                                               **{'command-line': 'info registers'})}
            if match:
                sample['jiffies'] = guest.call('human-monitor-command',
                                               **{'command-line': f'xp /1gx 0x{match[1]}'})
            samples.append(sample)
            time.sleep(.5)
        report['stall_samples'] = samples
    raise
finally:
    report['timer_trace'] = [line for line in guest.collect().splitlines()
                             if line.startswith(('TTF timer ', 'FAIL TTF '))]
    guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
