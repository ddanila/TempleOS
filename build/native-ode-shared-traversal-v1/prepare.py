from pathlib import Path
import shutil
import subprocess
import sys
from tempfile import TemporaryDirectory

root = Path(__file__).resolve().parent
parent = root.parent / 'native-ode-on-demand-v1'
subprocess.run([sys.executable, str(parent / 'prepare.py')], check=True)
with TemporaryDirectory(dir=root) as directory:
    scratch = Path(directory)
    shutil.copytree(parent / 'overlay', scratch, dirs_exist_ok=True)
    patch = (root / 'traversal.patch').read_bytes()
    subprocess.run(['patch', '-d', str(scratch), '-p1'], input=patch, check=True)
    shutil.copytree(scratch, root / 'overlay', dirs_exist_ok=True)
for name in ('Probe.HC', 'package.py', 'run.py'):
    shutil.copyfile(parent / name, root / name)
