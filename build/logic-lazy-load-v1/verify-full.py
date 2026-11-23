from pathlib import Path
import hashlib
import json
import runpy
import sys

root = Path(__file__).resolve().parent
image = root/'full/kernel.img'
sha = lambda blob: hashlib.sha256(blob).hexdigest()
image_data = image.read_bytes()
report = json.loads((root/'full/result.json').read_text())
assert report['disk_sha256'] == sha(image_data)
snapshot = runpy.run_path('tools/package-i386-native-image.py')['snapshot']
files = snapshot(image_data)[1]
entries = json.loads(Path('docs/i386-compatibility-inventory.json').read_text())['entries']
for entry in entries:
    path = entry['path']
    assert files['/'+path][2] == Path(path).read_bytes(), path
output = {
    'result': 'pass', 'image_sha256': sha(image_data),
    'inventory_files_matched': len(entries),
    'logic_loader_sha256': sha(files['/Apps/Logic/Load.HC'][2]),
    'boot_instruction_audit': report['boot_instruction_audit']['result'],
}
(root/'full-inventory.json').write_text(json.dumps(output, indent=2)+'\n')
runner = root/'run.py'
source = runner.read_text()
check = "!= [app_path]:"
assert source.count(check) == 1
source = source.replace(check, "!= []:")
source = source.replace('fixture, loader, guest_runner', 'fixture, loader, Path(verifier), guest_runner')
sys.argv = [str(runner), str(image), '--out', str(root/'full-play64')]
exec(compile(source, str(runner), 'exec'), {
    '__file__': str(runner), '__name__': '__main__', 'verifier': __file__,
})
