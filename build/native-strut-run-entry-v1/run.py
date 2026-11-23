import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import time

from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('disk', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
image = out / 'working.img'
shutil.copyfile(args.disk, image)
reference = 'cabe8f095a343976508794464b91044525c6442cfb0c8bad880fed30a1d5dc2b'
command = '#include "C:/Apps/Strut/Run.HC"'
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
report = {'result': 'running', 'command':command, 'input_sha256':sha(args.disk),
          'reference_instruction_crop_sha256':reference}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, out / 'guest', True)
try:
    guest.wait('DONE native kernel startup\n')
    start = len(guest.collect())
    guest.type(command)
    guest.press('ret')
    observed = None
    for _ in range(80):
        guest.screenshot('instructions')
        path = out / 'guest/instructions.png'
        crop = Image.open(path).convert('RGB').crop((0,8,630,120))
        observed = hashlib.sha256(crop.tobytes()).hexdigest()
        if observed == reference:
            break
        time.sleep(.35)
    else:
        raise ValueError(f'Run.HC did not display the expected instructions: {observed}')
    report['instruction_crop_sha256'] = observed
    guest.press('a')
    time.sleep(4)
    guest.screenshot('editor')
    with Image.open(out / 'guest/editor.png') as frame:
        editor_crop = hashlib.sha256(frame.convert('RGB').crop((0,8,630,120)).tobytes()).hexdigest()
    if editor_crop == observed:
        raise ValueError('Instruction key did not enter the editor')
    guest.press('esc')
    guest.wait('COMMAND OK\n',30,start)
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    guest.close()
    report['input_unchanged'] = report['input_sha256'] == sha(args.disk)
    (out / 'result.json').write_text(json.dumps(report,indent=2)+'\n')
