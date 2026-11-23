import argparse
import hashlib
import json
from pathlib import Path
import runpy
import time

parser = argparse.ArgumentParser()
parser.add_argument('iso', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(args.iso.resolve(), out / 'guest', False)
report = {'iso_sha256': hashlib.sha256(args.iso.read_bytes()).hexdigest()}
try:
    guest.wait('BALL model captured\n', 120)
    time.sleep(2)
    guest.type('BallGen;')
    guest.press('ret')
    time.sleep(5)
    guest.screenshot('ball-form')
    guest.press('esc')
    time.sleep(5)
    guest.screenshot('ball-form-escape')
    report['result'] = 'observed'
finally:
    guest.close()
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
