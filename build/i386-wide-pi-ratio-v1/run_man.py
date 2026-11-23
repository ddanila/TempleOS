"""Test whether wide pi expressions recover the exact original Man mesh."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('disk',type=Path)
parser.add_argument('--out',type=Path,required=True)
args=parser.parse_args()
out=args.out.resolve()
out.mkdir()
root=Path(__file__).resolve().parent
workflows=root.with_name('grmodels-menu-workflows-v1')
oracle=workflows/'man-original-tab/guest/MenuMesh.bin'
fixture=(workflows/'Observe.HC').read_bytes()+(root/'PiRatio.HC').read_bytes()
fixture+=b'''
F64 PiAngle(F64 degrees)
{
  F64 divisor=180.0;
  U64 result=PiRatio(degrees(U64),divisor(U64));
  return result(F64);
}
ModelObserve;
Cd("C:/Apps/GrModels");;
#include "/Kernel/I386/NativeModelGeometry.HC"
#include "/Adam/DolDoc/DocColorLightingCore.HC"
'''
source=Path('Apps/GrModels/ManGen.HC').read_bytes()
for angle in (b'ax',b'ay',b'az'):
    match=angle+b'*\xe3/180.0'
    if source.count(match)!=1:
        raise ValueError(f'Missing unique ManGen angle expression {match!r}')
    source=source.replace(match,b'PiAngle('+angle+b')')
fixture+=source+b'''
#include "BallGen"
#include "Models"
Models;
ModelCapture;
'''
working=out/'working.img'
pack=runpy.run_path('tools/package-i386-native-image.py')['package']
report={'fixture_sha256':hashlib.sha256(fixture).hexdigest(),
        'scope':'Experimental ManGen angle lowering in an observer overlay',
        'package':pack(args.disk,working,additions={'/WidePiMan.HC':fixture})}
Guest=runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
exercise=runpy.run_path(str(workflows/'run.py'))['exercise']
guest=Guest(working,out/'guest',True)
try:
    guest.wait('DONE native kernel startup\n')
    guest.type('#include "C:/WidePiMan.HC"')
    guest.press('ret')
    report['mesh']=exercise(guest,'man')
    actual=(guest.out/'MenuMesh.bin').read_bytes()
    report['exact']=actual==oracle.read_bytes()
    if not report['exact']:
        raise ValueError('Experimental wide-pi mesh differs from the original')
    report['result']='pass'
except Exception as error:
    report.update(result='fail',error=str(error))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
