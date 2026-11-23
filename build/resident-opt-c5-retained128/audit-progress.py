"""Check persisted retained modules whose successor command has started."""
import hashlib
import json
import re
import runpy
from pathlib import Path

root = Path(__file__).resolve().parent
tools = runpy.run_path('tools/test-i386-retained-build.py')
read = runpy.run_path('tools/build-i386-kernel.py')['mutated_file_contents']
log = (root/'qemu/debug.log').read_text()
started = re.findall(r'^INPUT LINE I386BuildModule\("C:/Kernel/I386/(\w+)\.HC"', log, re.M)
assert len(started) == len(set(started))
assert log.count('BUILD PROVIDER loaded\n') == 1
assert 'BUILD MODULE REJECT ' not in log
names = {f'/Probe/Retained{name}.t32m' for name in started[:-1]}
modules = read(root/'source.img', names)
assert modules.keys() == names and modules == read(root/'source.img', names)
verified = {}
for name in started[:-1]:
    module = modules[f'/Probe/Retained{name}.t32m']
    cross = (Path('build/resident-opt-public-v5/audit/exports')/f'{name}.t32m').read_bytes()
    records, exports = tools['exports_of'](module)
    _, expected = tools['exports_of'](cross)
    missing = set(expected) - set(exports)
    if name == 'CompilerRuntime':
        missing -= {'_I386_DIV_BEGIN', '_I386_DIV_END'}
    assert not missing and not (set(exports) - set(expected)), name
    if name == 'ConsoleRuntime':
        tools['check_console_alloc_wrappers'](module)
    verified[name] = dict(bytes=len(module), records=records, exports=len(exports),
                          module_sha256=hashlib.sha256(module).hexdigest(),
                          reference_sha256=hashlib.sha256(cross).hexdigest())
print(json.dumps(dict(scope=__doc__, modules=verified, latest_command=started[-1]), indent=2))
