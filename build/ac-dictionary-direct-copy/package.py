from pathlib import Path
import runpy

out = Path(__file__).resolve().parent
source = Path('build/resident-opt-public-v5/candidate.img')
packer = runpy.run_path('tools/package-i386-native-image.py')
snapshot, package = packer['snapshot'], packer['package']
path = '/Adam/AutoComplete/ACInit.HC'
replacement = (out/'ACInit.HC').read_bytes()

def configured(raw):
    tree, files, directories = snapshot(raw)
    attr, date, _ = files[path]
    files[path] = tree['Adam'][2]['AutoComplete'][2]['ACInit.HC'] = (attr, date, replacement)
    return tree, files, directories

package.__globals__['snapshot'] = configured
try:
    package(source, out/'candidate.img')
finally:
    package.__globals__['snapshot'] = snapshot
files = snapshot((out/'candidate.img').read_bytes())[1]
expected = configured(source.read_bytes())[1]
assert files == expected
