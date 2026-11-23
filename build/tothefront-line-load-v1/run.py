import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser = argparse.ArgumentParser()
parser.add_argument('disk',type=Path)
parser.add_argument('--out',type=Path,required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
source = Path('Adam/Gr/GrMath.HC').read_bytes()
setup = source[source.index(b'public Bool Line('):source.index(b'#help_index "Graphics/Math/3D Transformation"')]
packer = runpy.run_path('tools/package-i386-native-image.py')
image = out/'working.img'
report = {'result':'running','package':packer['package'](args.disk,image,additions={
    '/LineCore.HC':setup,
})}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image,out/'guest',True)
try:
    guest.wait('DONE native kernel startup\n')
    for command in ('#include "C:/LineCore.HC"','#include "C:/Apps/ToTheFront/Load.HC"'):
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
