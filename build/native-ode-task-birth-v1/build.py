import shutil
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parent
bootstrap = Path('build/native-focus-menu-psalmody-production-v1/bootstrap')
overlay = root / 'overlay'
for name in ('SchedulerCore.HC', 'CompilerTaskLayoutProbe.HC'):
    path = Path('Kernel/I386') / name
    target = overlay / path
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(path, target)
with (root / 'candidate.patch').open('rb') as patch:
    subprocess.run(['patch', '-d', str(overlay), '-p1'], stdin=patch, check=True)
builder = Path('tools/build-i386-kernel.py').resolve()
source = builder.read_text().replace('build/rebuild-test', str(bootstrap))
command = "'--overlay','tools/guest/i386-kernel','--output',str(iso))"
assert source.count(command) == 1
source = source.replace(command,
    "'--overlay','tools/guest/i386-kernel','--overlay'," +
    repr(str(overlay)) + ",'--output',str(iso))")
sys.argv = [str(builder), '--out', str(root / 'cross'), '--disk-mib', '64',
            '--content-profile', 'full', '--compiler-qmp-stdio', '--compiler-timeout', '240']
exec(compile(source, str(builder), 'exec'), {'__file__':str(builder), '__name__':'__main__'})
