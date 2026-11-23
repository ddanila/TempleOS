import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser()
parser.add_argument('disk',type=Path)
parser.add_argument('--app', choices=('GrModels','ToTheFront'), required=True)
parser.add_argument('--out',type=Path,required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
extras={}
if args.app=='GrModels':
    extras['/LightingChooser.HC'] = Path('Adam/DolDoc/DocColorLightingCore.HC').read_bytes()
packer = runpy.run_path('tools/package-i386-native-image.py')
image = out/'working.img'
report = {'result':'running','package':packer['package'](args.disk,image,additions=extras)}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image,out/'guest',True)
try:
    guest.wait('DONE native kernel startup\n')
    commands=['#include "C:/Kernel/I386/PublicGeometry.HH"']
    commands += [f'#include "C:{path}"' for path in extras]
    commands.append(f'#include "C:/Apps/{args.app}/Load.HC"')
    for command in commands:
        report['command']=command
        guest.command(command)
    guest.command('6*7;')
    report['fresh_result']=guest.result_pixels()
    report['result']='pass'
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
