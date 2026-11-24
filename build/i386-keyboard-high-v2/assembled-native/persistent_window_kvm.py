"""Run the retained-window fixture with the live KVM keyboard driver."""
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import sys

from PIL import Image

source, out = map(Path, sys.argv[1:])
out.mkdir()
digest = hashlib.sha256(source.read_bytes()).hexdigest()
working = out/'working.img'
shutil.copyfile(source, working)
fixture = runpy.run_path('tools/test-i386-persistent-window.py')
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(working, out/'guest', True)
report = {'result': 'running', 'source_sha256': digest, 'pixels': {}}
try:
    guest.wait('DONE native kernel startup\n')
    for command, _ in fixture['COMMANDS'][:-2]:
        guest.command(command)
    guest.type('PGView;')
    guest.press('ret')
    for label, color in [('A', (168, 0, 0)), ('B', (0, 168, 0)),
                         ('C', (0, 0, 168)), ('D', (255, 255, 255))]:
        guest.wait(f'PG {label}\n')
        guest.screenshot(label)
        with Image.open(guest.out/f'{label}.png') as screenshot:
            actual = screenshot.convert('RGB').getpixel((80, 80))
        if actual != color:
            raise ValueError(f'{label} pixel {actual} differs from {color}')
        report['pixels'][label] = actual
        guest.press('esc' if label == 'D' else 'spc')
    guest.wait('PG end\n')
    guest.command('6*7;')
    report['fresh_arithmetic'] = guest.result_pixels()
    if hashlib.sha256(source.read_bytes()).hexdigest() != digest:
        raise ValueError('Installed input disk changed')
    report['result'] = 'pass'
except Exception as error:
    report.update(result='fail', error=str(error))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
