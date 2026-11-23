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
root = Path(__file__).resolve().parent
expected = (root/'original/BallMesh.bin').read_bytes()
source = Path('Apps/GrModels/BallGen.HC').read_bytes()
serializer = source[:source.index(b'public U8 *BallGen()')]
records = Path('Adam/Gr/SpriteRecordsCore.HC').read_bytes()
table = records[:records.index(b'\n};')+4]
setup = b'#include "/Adam/Gr/Gr.HH"\n'+table+b'\n'+serializer
packer = runpy.run_path('tools/package-i386-native-image.py')
image = out/'working.img'
report = {'result':'running','package':packer['package'](args.disk,image,additions={
    '/BallSerializer.HC':setup,'/BallMeshProbe.HC':(root/'Probe.HC').read_bytes(),
})}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image,out/'guest',True)
try:
    guest.wait('DONE native kernel startup\n')
    for command in ('#include "C:/BallSerializer.HC"','#include "C:/BallMeshProbe.HC"'):
        report['command']=command
        guest.command(command)
    guest.command('BallMeshProbe;')
    guest.wait('BALL model captured\n',20)
    data = (out/'guest/BallMesh.bin').read_bytes()
    report['mesh_sha256']=hashlib.sha256(data).hexdigest()
    if data!=expected:
        raise ValueError('Native mesh differs from the original byte vector')
    guest.command('6*7;')
    report['fresh_result']=guest.result_pixels()
    report['result']='pass'
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
