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
table = Path('Adam/Gr/SpriteBaseSizes.HC').read_bytes()
setup = b'#include "/Adam/Gr/Gr.HH"\n'+table+b'\n'
matrix = Path('Adam/Gr/MatrixRotationCore.HC').read_bytes()
source = Path('Adam/DolDoc/DocGr.HC').read_bytes()
chooser = source[source.index(b'public I64 PopUpColorLighting'):source.index(b'class CTransformForm')]
setup += b'#define GR_SCALE (1<<32)\n' + matrix + b'\n' + chooser
packer = runpy.run_path('tools/package-i386-native-image.py')
image = out/'working.img'
report = {'result':'running','package':packer['package'](args.disk,image,additions={
    '/ModelRecords.HC':setup,
})}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image,out/'guest',True)
try:
    guest.wait('DONE native kernel startup\n')
    for command in ('#include "C:/ModelRecords.HC"','#include "C:/Apps/GrModels/Load.HC"'):
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
