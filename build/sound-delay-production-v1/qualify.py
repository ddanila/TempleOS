"""Verify the production image after the sound timing fix."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import hashlib
import json
import subprocess
import sys

root = Path(__file__).resolve().parent
disk = root / 'full/kernel.img'
tests = {
    'user8': ['tools/test-i386-user-startup.py', disk, '--out', root/'user8',
              '--managed-pointer', '--ram-mib', '8', '--accel', 'kvm'],
    'sound64': ['build/i386-graphics-registry-integration/sound-with-managed-pointer.py',
                disk, '--out', root/'sound64'],
    'fire64': ['build/tothefront-original-v1/run_phases.py', '--disk', disk, '--fire',
               '--out', root/'fire64'],
    'span64': ['build/span-production-v1/run.py', disk, '--out', root/'span64'],
    'source-audit': ['tools/audit-i386-delivered-source.py', '--disk', disk,
                     '--repository', '.', '--out', root/'source-audit/result.json'],
}


def read(path):
    return json.loads(path.read_text())


def run(item):
    name, args = item
    with (root / (name + '.log')).open('x') as log:
        code = subprocess.run([sys.executable, *map(str, args)], stdout=log,
                              stderr=subprocess.STDOUT).returncode
    receipt = root/name/'result.json'
    if not receipt.is_file():
        return name, {'result': 'fail', 'exit_code': code}
    result = read(receipt)
    return name, {'result': result['result'], 'exit_code': code,
                  'receipt_sha256': hashlib.sha256(receipt.read_bytes()).hexdigest()}


with ThreadPoolExecutor(max_workers=3) as pool:
    outcomes = dict(pool.map(run, tests.items()))
reference = read(Path('build/tothefront-original-v1/fire-original-adjacent/result.json'))
fire = read(root/'fire64/result.json')
match = all(reference.get(key) == fire.get(key)
            for key in ('fixture_sha256', 'direct_fire', 'phases'))
outcomes['original_fire_equivalence'] = {'result': 'pass' if match else 'fail'}
full = read(root/'full/result.json')
bootstrap = read(root/'bootstrap/result.json')
assert len(bootstrap['generations']) == 2 and bootstrap['result'] == 'pass'
passed = all(result['result'] == 'pass' and not result.get('exit_code')
             for result in outcomes.values())
report = {'result': 'pass' if passed else 'fail', 'tests': outcomes,
          'disk_sha256': hashlib.sha256(disk.read_bytes()).hexdigest(),
          'original_rebuilds': 2, 'inventory_files': len(full['volume']['inventory_sha256']),
          'user8_seconds': read(root/'user8/result.json').get('behavior', {}).get('startup_seconds'),
          'delivered_source_files': read(root/'source-audit/result.json')['source_files']}
(root/'qualification.json').write_text(json.dumps(report, indent=2)+'\n')
if not passed:
    raise SystemExit(1)
