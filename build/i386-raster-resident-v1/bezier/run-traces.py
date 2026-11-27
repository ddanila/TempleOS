from hashlib import sha256
import json
from pathlib import Path
from runpy import run_path
import sys

disk, output, fixture = (Path(arg).resolve() for arg in sys.argv[1:])
output.mkdir()
work = output / 'working.img'
driver = run_path('tools/test-i386-autocomplete-interaction.py')
pack = run_path('tools/package-i386-native-image.py')
data = disk.read_bytes()
_, files, _ = pack['snapshot'](data)
module = files['/Modules/I386/ConsoleRuntime.t32m'][2]
symbols = {name: start for start, _, name in
           run_path('tools/profile-i386-boot.py')['symbols'](module, 0)}
source = '''I64 TraceWrite(U8 *name,U8 *data,I64 bytes)
{
  U8 *path=MStrPrint("C:/%s",name);
  I64 result=FileWrite(path,data,bytes);
  Free(path);return result;
}
#define TRACE_WRITE TraceWrite
'''
for key, function in [('SECOND','Bezier2'), ('THIRD','Bezier3')]:
    offset = symbols[function] - symbols['Gr2BSpline']
    source += f'#define BEZIER_{key} ((&Gr2BSpline)(U8 *)+({offset}))\n'
source += fixture.read_text()
pack['package'](disk, work, {'/Trace.HC': source.encode()})
guest = driver['Guest'](work, output / 'guest', True, ram_mib=64)
digest = sha256(data).hexdigest()
try:
    guest.wait('DONE native kernel startup\n')
    guest.command('#include "C:/Trace.HC"')
    guest.command('U0 TraceLog(U8 *s){while(*s)OutU8(0xE9,*s++);}')
    guest.command('U8 *trace_mask=MStrPrint("TRACE MASK %d\\n",TraceBezier);TraceLog(trace_mask);Free(trace_mask);')
    assert 'TRACE MASK 255\n' in guest.collect()
    guest.command('6*7;')
    guest.result_pixels()
finally:
    guest.close()
assert sha256(disk.read_bytes()).hexdigest() == digest
_, files, _ = pack['snapshot'](work.read_bytes())
report = {'disk_sha256': digest, 'inputs_unchanged': True, 'traces': {}}
for order in (2, 3):
    for mode in range(4):
        name = f'Trace{order}{mode}.BIN'
        trace = files['/' + name][2]
        assert len(trace) % 24 == 0
        (output / name).write_bytes(trace)
        report['traces'][name] = {'sha256': sha256(trace).hexdigest(),
                                  'sample_count': len(trace) // 24}
(output/'result.json').write_text(json.dumps(report, indent=2) + '\n')
