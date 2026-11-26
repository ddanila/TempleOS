"""Separate the missing processor-count symbol from later worker dependencies."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('image', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
args.out.mkdir()
working = args.out / 'working.img'
shutil.copyfile(args.image, working)
digest = hashlib.sha256(args.image.read_bytes()).hexdigest()
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(working, args.out / 'guest', True)
report = {'result': 'running', 'image_sha256': digest, 'commands': {}}
try:
    guest.wait('DONE native kernel startup\n')
    commands = ('mp_cnt;', '#define mp_cnt 1',
                '#include "C:/Demo/MagicPairs.HC"', '6*7;')
    for command in commands:
        try:
            guest.command(command)
        except ValueError as error:
            report['commands'][command] = {'result': 'reject', 'diagnostic': str(error)}
        else:
            report['commands'][command] = {'result': 'accept'}
    if report['commands']['6*7;']['result'] != 'accept':
        raise ValueError('Native prompt failed to recover')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
finally:
    guest.close()
    report['inputs_unchanged'] = hashlib.sha256(args.image.read_bytes()).hexdigest() == digest
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
