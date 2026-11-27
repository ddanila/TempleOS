from hashlib import sha256
import json
from pathlib import Path
from runpy import run_path
import shutil
import sys

source, output = (Path(arg).resolve() for arg in sys.argv[1:])
image = output / 'installed.img'
digest = lambda path: sha256(path.read_bytes()).hexdigest()
read = run_path('tools/build-i386-kernel.py')['mutated_file_contents']
source_hash = digest(source)
built_path = '/Probe/RetainedDocDiagnosticRuntime.t32m'
installed_path = '/Modules/I386/DocDiagnosticRuntime.t32m'
module = read(source, {built_path})[built_path]
assert not image.exists()
shutil.copyfile(source, image)
guest = run_path('tools/test-i386-autocomplete-interaction.py')['Guest'](
    image, output/'install', True, ram_mib=16)
try:
    guest.wait('DONE native kernel startup\n')
    guest.command(f'if(!(FileDel("C:{installed_path}")&&FileMove("C:{built_path}","C:{installed_path}")))throw(\'Install\',TRUE);')
    guest.command('6*7;')
    guest.result_pixels()
finally:
    guest.close()
assert digest(source) == source_hash
assert read(image, {built_path, installed_path}) == {installed_path: module}
verify = run_path('tools/build-i386-kernel.py')['verify_mutated_volume']
receipt = dict(result='pass', source_sha256=source_hash, image_sha256=digest(image),
               module_sha256=sha256(module).hexdigest(), module_bytes=len(module),
               verified_volume=verify(image), arithmetic=42)
(output/'install-result.json').write_text(json.dumps(receipt, indent=2)+'\n')
