"""Check the public compiler option names independently at the native prompt."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('image', type=Path)
parser.add_argument('--out', type=Path, required=True)
parser.add_argument('--load-shared', action='store_true')
parser.add_argument('--published', action='store_true', help='Exercise the startup-published implementation')
parser.add_argument('--ram-mib', type=int, choices=(8, 64), default=64)
args = parser.parse_args()
args.out.mkdir()
source = args.image
image = args.out / 'working.img'
shutil.copyfile(source, image)
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image, args.out / 'guest', True, ram_mib=args.ram_mib)
report = {'result': 'running', 'image_sha256': hashlib.sha256(source.read_bytes()).hexdigest(), 'commands': {}, 'ram_mib': args.ram_mib}
try:
    guest.wait('DONE native kernel startup\n')
    commands = ('OPTf_WARN_PAREN;', 'Option(17,ON);', 'GetOption(17);')
    if args.load_shared or args.published:
        commands = (
            "Bool old=GetOption(17);if(Option(17,!old)!=old || GetOption(17)==old)throw('Opt',TRUE);Option(17,old);",
            '#include "C:/Demo/ParenWarn.HC"',
        )
        if args.load_shared:
            commands = ('#include "C:/Compiler/PrsOptions.HC"', *commands)
    for command in commands:
        try:
            guest.command(command)
        except ValueError as error:
            report['commands'][command] = {'result': 'reject', 'diagnostic': str(error)}
        else:
            report['commands'][command] = {'result': 'accept'}
    if args.published and any(command['result'] != 'accept' for command in report['commands'].values()):
        raise ValueError('Startup-published option functions rejected an input')
    guest.command('6*7;')
    report['fresh_result'] = guest.result_pixels()
    report['result'] = 'pass'
finally:
    guest.close()
    (args.out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
