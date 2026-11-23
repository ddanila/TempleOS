from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parent
disk = root / 'full/kernel.img'
commands = {
    'source-audit': ['tools/audit-i386-delivered-source.py', '--disk', disk,
                     '--repository', '.', '--out', root/'source-audit/result.json'],
    'user8': ['tools/test-i386-user-startup.py', disk, '--out', root/'user8',
              '--managed-pointer', '--ram-mib', '8', '--accel', 'kvm'],
    'strut64': ['build/native-strut-entry-v1/run.py', disk, '--out', root/'strut64'],
    'span64': [root/'run.py', disk, '--out', root/'span64'],
    'interchange64': [root/'interchange.py', disk, '--out', root/'interchange64'],
}


def run(item):
    name, args = item
    with (root / (name+'.log')).open('w') as stream:
        completed = subprocess.run([sys.executable, *args], stdout=stream,
                                   stderr=subprocess.STDOUT)
    print(name, completed.returncode, flush=True)
    return completed.returncode


with ThreadPoolExecutor(max_workers=5) as pool:
    failures = list(pool.map(run, commands.items()))
if any(failures):
    raise SystemExit(1)
