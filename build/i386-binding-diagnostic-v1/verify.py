"""Reproduce the missing WidePi dependency, then boot the matching image."""
import hashlib
import json
import runpy
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parent
source = root / 'full/kernel.img'
old = Path('build/i386-console-null-slots-v1/retained128/source.img')
fixture = '/Probe/RetainedCompilerRuntime.t32m'
read = runpy.run_path('tools/build-i386-kernel.py')['mutated_file_contents']
modules = read(old, {fixture})
if set(modules) != {fixture}:
    raise ValueError('Missing old guest CompilerRuntime fixture')
audit = runpy.run_path('tools/test-i386-retained-build.py')['exports_of']
symbol = 'I386F64PiMulDiv'
if symbol in audit(modules[fixture])[1]:
    raise ValueError('Old fixture exports the missing binding')
pack = runpy.run_path('tools/package-i386-native-image.py')['package']
mixed = root / 'missing-binding.img'
pack(source, mixed, additions=modules)
install = root / 'missing-binding-install'
negative = subprocess.run([
    sys.executable, 'tools/test-i386-retained-install.py',
    '--source', str(mixed), '--out', str(install),
    '--module', 'CompilerRuntime', '--cpu', '486,-fpu', '--accel', 'kvm',
    '--welcome', '--managed-pointer', '--qmp-stdio',
])
evidence = (install / 'boot/debug.log').read_text().splitlines()
marker = 'BINDING MISSING ' + symbol
if negative.returncode == 0 or evidence[-2:] != [marker, 'FAIL native kernel']:
    raise ValueError('Expected the missing binding to be logged before halting')
positive = root / 'user8'
subprocess.run([
    sys.executable, 'tools/test-i386-user-startup.py', str(source),
    '--out', str(positive), '--ram-mib', '8', '--accel', 'kvm', '--managed-pointer',
], check=True)
report = {
    'result': 'pass',
    'cross_disk_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
    'older_compiler_sha256': hashlib.sha256(modules[fixture]).hexdigest(),
    'mixed_disk_sha256': hashlib.sha256((install / 'candidate.img').read_bytes()).hexdigest(),
    'expected_failure_tail': evidence[-2:],
    'positive_receipt_sha256': hashlib.sha256((positive / 'result.json').read_bytes()).hexdigest(),
}
(root / 'qualification.json').write_text(json.dumps(report, indent=2) + '\n')
