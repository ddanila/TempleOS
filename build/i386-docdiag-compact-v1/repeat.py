from hashlib import sha256
import json
from pathlib import Path
from runpy import run_path
import sys

disk, out = (Path(p).resolve() for p in sys.argv[1:])
out.mkdir()
scope = run_path('tools/test-i386-doc-diagnostic-separation.py')
console = disk.parent/'exports/ConsoleRuntime.t32m'
diagnostics = disk.parent/'exports/DocDiagnosticRuntime.t32m'
assert not scope['CHECKS'] & scope['exports'](console)
assert scope['CHECKS'] <= scope['exports'](diagnostics)
pins = {str(path): sha256(path.read_bytes()).hexdigest() for path in (disk,console,diagnostics)}
guest = run_path('tools/test-i386-autocomplete-interaction.py')['Guest'](
    disk,out/'guest',True,ram_mib=64,native_options=('-snapshot',))
try:
    guest.wait('DONE native kernel startup\n')
    assert 'DOC DIAGNOSTIC loaded\n' not in guest.collect()
    guest.command('U0 DDCheck(I64 n){U8 *s=MStrPrint("DOC CHECK RET %d\\n",n),*p=s;while(*p)OutU8(0xE9,*p++);Free(s);}')
    for _ in range(2):
        guest.command('DDCheck(DocAllocationCheck);')
    log = guest.collect()
    markers = ('DOC CHECK RET 13\n', 'DOC DIAGNOSTIC loaded\n',
               'DOC DOLLAR GROWTH recovery\n', 'DOC DIAGNOSTIC unloaded\n')
    counts = {marker.strip():log.count(marker) for marker in markers}
    assert all(count == 2 for count in counts.values()), counts
    guest.command('6*7;')
    guest.result_pixels()
finally:
    guest.close()
assert all(sha256(Path(path).read_bytes()).hexdigest() == pin for path,pin in pins.items())
report = dict(result='pass',ram_mib=64,accel='kvm',cpu='486,-fpu',counts=counts,
              input_sha256=pins,inputs_unchanged=True,arithmetic=42)
(out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
