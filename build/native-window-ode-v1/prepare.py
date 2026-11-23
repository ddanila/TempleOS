from pathlib import Path
import re
import shutil
import subprocess
from tempfile import TemporaryDirectory

root = Path(__file__).resolve().parent
overlay = root / 'overlay'
patch = (root / 'candidate.patch').read_bytes()
with TemporaryDirectory(dir=root) as directory:
    scratch = Path(directory)
    for match in re.finditer(rb'^--- a/(Kernel/I386/[^\n]+)$', patch, re.M):
        source = Path(match[1].decode())
        target = scratch / source
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    subprocess.run(['patch', '-d', str(scratch), '-p1'], input=patch, check=True)
    shutil.copyfile('build/strut-native-raster-bindings-v1/overlay/Once.HC', scratch / 'Once.HC')
    shutil.copytree(scratch, overlay, dirs_exist_ok=True)
