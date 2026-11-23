import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
image = out/'working.img'
shutil.copyfile(args.disk, image)
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
play = runpy.run_path('build/tothefront-original-v1/startup.py')['play']
guest = Guest(image, out/'guest', True)
command = '#include "C:/Apps/ToTheFront/Run.HC"'
report = {'command': command, 'input_sha256': hashlib.sha256(args.disk.read_bytes()).hexdigest()}
try:
    guest.wait('DONE native kernel startup\n')
    start = len(guest.collect())
    guest.type(command)
    guest.press('ret')
    guest.wait('COMPILER BREAK ready', start=start)
    time.sleep(15)
    play(guest)
    guest.wait('COMMAND OK\n', timeout=45, start=start)
    guest.command('6*7;')
    report.update(result='pass', after_match=guest.result_pixels())
except Exception as error:
    report.update(result='fail', error=str(error)[:3000])
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
