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
irq = parser.add_mutually_exclusive_group()
irq.add_argument('--userspace-irqchip', action='store_true')
irq.add_argument('--split-irqchip', action='store_true')
stimulus = parser.add_mutually_exclusive_group()
stimulus.add_argument('--single-note', action='store_true')
stimulus.add_argument('--note-burst', action='store_true')
stimulus.add_argument('--fixed-noise', action='store_true')
stimulus.add_argument('--worker-burst', action='store_true')
parser.add_argument('--discard-lost-ticks', action='store_true')
parser.add_argument('--poll-parent', action='store_true')
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
fixture = Path(__file__).with_name('NoiseSleep.HC').read_bytes()
if args.single_note or args.note_burst:
    start = fixture.index(b'  sound=Noise(')
    end = fixture.index(b'  start=cnts.jiffies;', start)
    notes = b'  sound=0;\n  Snd(34);\n'
    if args.note_burst:
        fixture = fixture.replace(b'  I64 start;', b'  I64 start,i;')
        start = fixture.index(b'  sound=Noise(')
        end = fixture.index(b'  start=cnts.jiffies;', start)
        notes = b'''  sound=0;
  NoiseSleepLog("TTF timer before note burst\\n");
  for (i=0;i<16;i++) {
    Snd(34+i%2*7);
    Sleep(15);
  }
  NoiseSleepLog("TTF timer after note burst\\n");
'''
    fixture = fixture[:start] + notes + fixture[end:]
    fixture = fixture.replace(b'  NoiseSleepLog(report);\n}', b'  NoiseSleepLog(report);\n  Snd;\n}')
if args.worker_burst:
    worker = b'''Bool noise_burst_done;
U0 NoiseBurstWorker(I64 ignored)
{
  I64 i;
  for (i=0;i<16;i++) {
    Snd(34+i%2*7);
    Sleep(15);
  }
  Snd;
  noise_burst_done=TRUE;
}
'''
    fixture = worker + fixture.replace(
        b'  sound=Noise(250,34,41);',
        b'  noise_burst_done=FALSE;\n  sound=Spawn(&NoiseBurstWorker);')
    fixture = fixture.replace(
        b'  Sleep(250);\n  StrPrint(report,"TTF timer after active noise',
        b'  Sleep(400);\n  if (!noise_burst_done) {\n'
        b'    NoiseSleepLog("FAIL TTF speaker worker incomplete\\n");\n'
        b'    return;\n'
        b'  }\n'
        b'  StrPrint(report,"TTF timer after active noise')
if args.fixed_noise:
    fixture = fixture.replace(b'Noise(250,34,41)', b'Noise(250,34,34)')
if args.poll_parent:
    fixture = fixture.replace(
        b'  Sleep(250);\n  StrPrint(report,"TTF timer after active noise',
        b'  while(cnts.jiffies-start<250) Sleep(5);\n  StrPrint(report,"TTF timer after active noise')
working = out/'working.img'
package = runpy.run_path('tools/package-i386-native-image.py')['package']
report = {'package': package(args.disk, working, additions={'/NoiseSleep.HC': fixture}),
          'fixture_sha256': hashlib.sha256(fixture).hexdigest(), 'single_note': args.single_note, 'note_burst': args.note_burst, 'fixed_noise': args.fixed_noise,
          'poll_parent': args.poll_parent, 'worker_burst': args.worker_burst}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
machine = 'pc,kernel-irqchip=off' if args.userspace_irqchip else 'pc'
if args.split_irqchip:
    machine = 'pc,kernel-irqchip=split'
report['machine'] = machine
options = ('-global', 'kvm-pit.lost_tick_policy=discard') if args.discard_lost_ticks else ()
report['native_options'] = options
guest = Guest(working, out/'guest', True, native_machine=machine, native_options=options)
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
            sample['pic'] = guest.call('human-monitor-command',
                                       **{'command-line': 'info pic'})
            if match:
                sample['jiffies'] = guest.call('human-monitor-command',
                                               **{'command-line': f'xp /1gx 0x{match[1]}'})
            samples.append(sample)
            time.sleep(.5)
        report['stall_samples'] = samples
    raise
finally:
    report['timer_trace'] = [line for line in guest.collect().splitlines()
                             if line.startswith(('TTF timer ', 'FAIL TTF ', 'NOISE step '))]
    guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
