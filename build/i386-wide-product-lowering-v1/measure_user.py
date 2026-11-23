import argparse
import json
from pathlib import Path
import re
import runpy

parser = argparse.ArgumentParser()
parser.add_argument('image', type=Path)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
user = runpy.run_path('tools/test-i386-user-startup.py')
packer = runpy.run_path('tools/package-i386-native-image.py')
working = out / 'working.img'
packer['package'](args.image, working, additions={'/UserStartup.HC': user['FIXTURE'].read_bytes()})
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
decode = runpy.run_path('tools/observe-i386-heap-pressure.py')['blocks']
guest = Guest(working, out / 'guest', True, ram_mib=8)
report = {}
try:
    initial = guest.wait('DONE native kernel startup\n')
    for command, _ in user['COMMANDS'][:3]:
        guest.command(command)
    for name, marker in [('main', 'ARENA'), ('fallback', 'TASK FALLBACK ARENA')]:
        base, size = (int(part, 16) for part in re.search(
            rf'^{marker} ([0-9A-F]+) ([0-9A-F]+)$', initial, re.M).groups())
        path = out / f'{name}.bin'
        guest.call('pmemsave', val=base, size=size, filename=str(path))
        rows = decode(path.read_bytes(), base)
        free = [row['span'] - 16 for row in rows if not row['used']]
        report[name] = {'largest_payload': max(free), 'total_payload': sum(free),
                        'free_blocks': len(free)}
    try:
        guest.command('USCheck;')
        report['result'] = 'pass'
    except ValueError as error:
        report.update(result='fail', rejection=str(error))
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
