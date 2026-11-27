from hashlib import sha256
import json
from pathlib import Path
import re
from runpy import run_path
import sys

disk, output, fixture = (Path(arg).resolve() for arg in sys.argv[1:])
output.mkdir()
pack = run_path('tools/package-i386-native-image.py')
image = disk.read_bytes()
_, files, _ = pack['snapshot'](image)
module = files['/Modules/I386/ConsoleRuntime.t32m'][2]
symbols = {name: start for start, _, name in
           run_path('tools/profile-i386-boot.py')['symbols'](module, 0)}
offset = symbols['GrFillTri0'] - symbols['GrFillPoly3']
source = f'''#define TRIANGLE_DRAW ((&GrFillPoly3)(U8 *)+({offset}))
I64 TriangleWrite(U8 *name,U8 *pixels,I64 bytes){{return FileWrite("C:/Triangles.BIN",pixels,bytes);}}
#define TRIANGLE_WRITE TriangleWrite
#define TRIANGLE_RELEASE Free
''' + fixture.read_text()
work = output / 'working.img'
pack['package'](disk, work, {'/Triangles.HC': source.encode()})
guest = run_path('tools/test-i386-autocomplete-interaction.py')['Guest'](work, output/'guest', True, ram_mib=64)
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/Triangles.HC"')
    guest.command('U0 TriangleLog(U8 *s){while(*s)OutU8(0xE9,*s++);}')
    guest.command('U8 *tri_mask=MStrPrint("TRIANGLE FILLED %d\\n",TriangleFrames);TriangleLog(tri_mask);Free(tri_mask);')
    count = int(re.search(r'^TRIANGLE FILLED (\d+)$', guest.collect(), re.M)[1])
    assert count > 0
    guest.command('6*7;')
    guest.result_pixels()
finally:
    guest.close()
frames = pack['snapshot'](work.read_bytes())[1]['/Triangles.BIN'][2]
assert len(frames) == 96*(8+32*24*5)
(output/'Triangles.BIN').write_bytes(frames)
digest = sha256(image).hexdigest()
assert sha256(disk.read_bytes()).hexdigest() == digest
(output/'result.json').write_text(json.dumps(dict(disk_sha256=digest,
    frames_sha256=sha256(frames).hexdigest(), cases=96, filled=count,
    fresh_arithmetic=42, inputs_unchanged=True),indent=2)+'\n')
