#!/usr/bin/env python3
"""Qualify the existing debugger contracts against one frozen image and harness."""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def jobs(cycles):
    repeated = ['--cycles', str(cycles)]
    selected = [
        ('register-' + register, 'test-i386-debug-register-banks.py',
         [*repeated, '--register', register])
        for register in ('eax', 'ecx', 'edx', 'ebx', 'esi', 'edi')]
    selected += [
        ('public-flags', 'test-i386-debug-public-flags.py', repeated),
        ('step-flags', 'test-i386-debug-public-step-flags.py', repeated),
        ('step-ip', 'test-i386-debug-public-step-ip.py', repeated),
        ('public-stack', 'test-i386-debug-public-stack.py', repeated),
        ('step-stack', 'test-i386-debug-public-step-stack.py', repeated),
        ('initial-alternate-stack', 'test-i386-debug-initial-alternate-stack.py', repeated),
        ('stack-overlap-down', 'test-i386-debug-public-stack-overlap.py', [*repeated, '--delta', '-4']),
        ('stack-overlap-up', 'test-i386-debug-public-stack-overlap.py', [*repeated, '--delta', '4']),
        ('breakpoint-lifecycle', 'test-i386-debug-breakpoint-lifecycle.py', repeated),
        ('breakpoint-task-switch', 'test-i386-debug-breakpoint-task-switch.py', []),
        ('breakpoint-same-address', 'test-i386-debug-breakpoint-task-switch.py', ['--both-own']),
        ('concurrent-repeat', 'test-i386-debug-concurrent-repeat.py', repeated),
        ('concurrent-kill', 'test-i386-debug-concurrent-kill.py', []),
        ('caller-debugger-stack', 'test-i386-debug-cpu-trace.py', [*repeated, '--public-caller']),
    ]
    return selected


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--cycles', type=int, default=5)
    parser.add_argument('--workers', type=int, default=2)
    parser.add_argument('--writable-copies',action='store_true',help='Use isolated disk copies where QEMU snapshot temporary files are unavailable')
    args = parser.parse_args()
    if not 1 <= args.cycles <= 20 or not 1 <= args.workers <= 4:
        parser.error('Use 1..20 cycles and 1..4 workers')
    disk, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    digest = sha(disk)
    out.mkdir(parents=True)
    snapshot = out / 'harness'
    sources = [ROOT / 'Kernel/FontStd.HC', ROOT / 'Kernel/KDbg.HC',
               *sorted((ROOT / 'tools').glob('*.py'))]
    inputs = {str(disk): digest}
    for source in sources:
        identity = sha(source)
        dest = snapshot / source.relative_to(ROOT)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, dest)
        if sha(source) != identity or sha(dest) != identity:
            raise ValueError('Helper changed while freezing: ' + str(source))
        inputs[str(dest)] = identity
    selected = jobs(args.cycles)
    report = dict(result='running', disk_sha256=digest, input_sha256=inputs,
                  cpu='486,-fpu', ram_mib=8, cycles=args.cycles,
                  disk_policy='writable copies' if args.writable_copies else 'QEMU snapshots',
                  expected_jobs=[name for name, _, _ in selected], jobs={},
                  scope='Existing debugger register/step/stack/breakpoint/concurrency/Caller contracts on one image; not complete API parity, native rebuilding or release acceptance')

    def unchanged():
        if any(sha(Path(path)) != identity for path, identity in inputs.items()):
            raise ValueError('Debugger qualification inputs changed')

    def save():
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')

    def run(job):
        name, tool, options = job
        unchanged()
        environment=os.environ.copy()
        if args.writable_copies:
            environment['TEMPLEOS_QEMU_WRITABLE_SNAPSHOTS']='1'
        else:
            environment.pop('TEMPLEOS_QEMU_WRITABLE_SNAPSHOTS',None)
        with (out / (name + '.log')).open('w') as log:
            subprocess.run([sys.executable, str(snapshot / 'tools' / tool),
                            str(disk), '--out', str(out / name), *options],
                           cwd=snapshot, env=environment, stdout=log, stderr=subprocess.STDOUT, check=True)
        path = out / name / 'result.json'
        result = json.loads(path.read_text())
        if (result.get('result') != 'pass' or result.get('disk_sha256') != digest
                or result.get('source_disk_unchanged') is not True):
            raise ValueError('Missing passing immutable-image debugger result: ' + name)
        behavior = result.get('behavior', {})
        if (behavior.get('result'), behavior.get('cpu'), behavior.get('ram_mib'),
                behavior.get('vga')) != ('pass', '486,-fpu', 8,
                                          'all pixels matched at each checkpoint'):
            raise ValueError('Wrong debugger execution profile: ' + name)
        if args.writable_copies:
            provenance=out/name/'behavior/snapshot-provenance.json'
            storage=json.loads(provenance.read_text())
            if storage.get('source_disk_sha256')!=digest or storage.get('policy')!='writable disk copy':
                raise ValueError('Wrong copied debugger disk provenance: '+name)
        unchanged()
        return dict(result=result, result_sha256=sha(path))

    try:
        save()
        errors = []
        with ThreadPoolExecutor(max_workers=args.workers) as pool:
            futures = {pool.submit(run, job): job[0] for job in selected}
            for future in as_completed(futures):
                name = futures[future]
                try:
                    report['jobs'][name] = future.result()
                except Exception as error:
                    report['jobs'][name] = dict(result='fail', error=str(error))
                    errors.append(name + ': ' + str(error))
                save()
        unchanged()
        if errors:
            raise ValueError('; '.join(errors))
        report.update(result='pass', source_disk_unchanged=True)
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        save()


if __name__ == '__main__':
    main()
