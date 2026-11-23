import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
out = args.out.resolve()
out.mkdir()
overlay = out/'overlay'
reference = runpy.run_path('tools/test-i386-timeclock-reference.py')
sources = reference['restore_reference'](overlay)
fixture = Path(__file__).with_name('Probe.HC')
(overlay/'Once.HC').write_bytes(
    b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n'
    b'#include "T:/Apps/GrModels/Load.HC"\n'
    + fixture.read_bytes() + b'\nBallMeshProbe;\n')
image = out/'original.iso'
subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],
               check=True)
report = {'result':'running','source_sha256':{
    path:digest for path,digest in sources.items() if path.startswith('Apps/GrModels/')}}
Guest = runpy.run_path('tools/test-i386-autocomplete-interaction.py')['Guest']
guest = Guest(image,out/'guest',False)
try:
    guest.wait('BALL model captured\n',90)
    data = (out/'guest/BallMesh.bin').read_bytes()
    vertices, triangles = struct.unpack_from('<ii',data,1)
    coordinates = struct.unpack_from('<9i',data,9)
    if (vertices,triangles) != (3,1) or coordinates != (-12,3,7,20,-4,1,0,8,-9):
        raise ValueError('Original triangle counts or coordinates differ')
    expected = struct.pack('<Bii9i4iB',24,3,1,-12,3,7,20,-4,1,0,8,-9,12,0,1,2,0)
    if data != expected:
        raise ValueError('Original sprite type, triangle, or end record differs')
    report.update(result='pass',bytes=len(data),vertices=vertices,triangles=triangles,
                  mesh_sha256=hashlib.sha256(data).hexdigest())
except Exception as exc:
    report.update(result='fail',error=str(exc))
    raise
finally:
    guest.close()
    (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
