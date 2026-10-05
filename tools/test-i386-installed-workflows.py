#!/usr/bin/env python3
"""Run four installed workstation gates on a qualified guest-built image."""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import runpy
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_image_origin(disk, native, audit, native_disk=None, packaging_result=None):
    """Bridge an audited native disk to its reproducibly packaged descendant."""
    digest = sha(disk)
    qualified = digest
    inputs = []
    if (native_disk is None) != (packaging_result is None):
        raise ValueError('Provide both --native-disk and --packaging-result')
    if native_disk is not None:
        qualified = sha(native_disk)
        report = json.loads(packaging_result.read_text())
        if (report.get('result') != 'pass' or
                report.get('source_sha256') != qualified or
                report.get('image_sha256') != digest or
                report.get('source_unchanged') is not True):
            raise ValueError('Packaging report does not connect these exact images')
        packer = ROOT / 'tools/package-i386-native-image.py'
        pack = runpy.run_path(str(packer))['package']
        # Recompute rather than trusting a claimed hash or modifying native evidence.
        with tempfile.TemporaryDirectory(prefix='i386-package-origin-') as directory:
            rebuilt = Path(directory) / 'native.img'
            pack(native_disk, rebuilt)
            if rebuilt.read_bytes() != disk.read_bytes():
                raise ValueError('Disk differs from deterministic native packaging')
        inputs = [native_disk, packaging_result, packer,
                  ROOT / 'tools/build-i386-kernel.py']
    if (native.get('result') != 'pass' or
            native.get('retained_origin') != 'guest-built supplied inputs' or
            native.get('target_disk_sha256') != qualified):
        raise ValueError('Native prerequisite must qualify this exact native disk')
    if (audit.get('result') != 'pass' or
            audit.get('installed_disk_sha256') != digest or
            audit.get('installed_payload') != 'matches guest-built flat image' or
            not native.get('flat_sha256') or
            native['flat_sha256'] != audit.get('flat_sha256')):
        raise ValueError('Installed audit must qualify this exact disk and native flat payload')
    return inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('disk', 'native-result', 'installed-audit', 'out'):
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--native-disk', type=Path,
                        help='Original qualified native image before deterministic packaging')
    parser.add_argument('--packaging-result', type=Path,
                        help='Packaging report connecting original and requested image')
    args = parser.parse_args()
    disk, native_path, audit_path, out = [p.resolve() for p in
        (args.disk, args.native_result, args.installed_audit, args.out)]
    if out.exists():
        parser.error('Use a fresh output directory; existing evidence is preserved')
    native = json.loads(native_path.read_text())
    audit = json.loads(audit_path.read_text())
    try:
        origin_inputs = verify_image_origin(disk, native, audit,
            args.native_disk.resolve() if args.native_disk else None,
            args.packaging_result.resolve() if args.packaging_result else None)
    except ValueError as error:
        parser.error(str(error))
    # Execute frozen helpers so unrelated development cannot alter this run.
    out.mkdir(parents=True)
    snapshot = out / 'harness'
    helper_sources = [ROOT / 'Kernel/FontStd.HC',
                      *sorted((ROOT / 'tools').glob('*.py'))]
    helper_identity = {}
    for source in helper_sources:
        digest = sha(source)
        destination = snapshot / source.relative_to(ROOT)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        if sha(destination) != digest or sha(source) != digest:
            raise ValueError('Helper changed while creating snapshot: ' + str(source))
        helper_identity[str(source.relative_to(ROOT))] = digest
    inputs = {str(p): sha(p) for p in
              [disk, native_path, audit_path, *origin_inputs,
               *[snapshot / name for name in helper_identity]]}
    jobs = [
        ('workstation', 'i386-kernel-input.py',
         [disk, '--cpu', '486,-fpu', '--qmp-stdio', '--writable-copy'], 'result.json'),
        ('doldoc-session', 'test-i386-doldoc-session.py',
         [disk, '--cpu', '486,-fpu', '--qmp-stdio'], 'result.json'),
        ('speaker', 'test-i386-speaker-output.py', [disk], 'result.json'),
        ('resource', 'test-i386-resource-profile.py',
         ['--disk', disk, '--accel', 'tcg'], 'resource-result.json'),
    ]
    report = {'result': 'running', 'cpu': '486,-fpu', 'ram_mib': 8,
              'accel': 'tcg', 'input_sha256': inputs,
              'harness_sha256': helper_identity, 'jobs': {},
              'image_origin': 'deterministically packaged native image' if origin_inputs else 'native installed image'}

    def save():
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')

    def unchanged():
        if any(sha(Path(path)) != value for path, value in inputs.items()):
            raise ValueError('Qualification inputs changed during execution')

    def run(job):
        name, tool, arguments, result_name = job
        unchanged()
        with (out / (name + '.log')).open('w') as log:
            subprocess.run([sys.executable, str(snapshot / 'tools' / tool),
                            *map(str, arguments), '--out', str(out / name)],
                           cwd=snapshot, stdout=log, stderr=subprocess.STDOUT, check=True)
        path = out / name / result_name
        result = json.loads(path.read_text())
        if result.get('result') != 'pass':
            raise ValueError(name + ' did not pass')
        budget = runpy.run_path(str(snapshot / 'tools/check-i386-installed-budgets.py'))['assess_job'](name, result)
        (out / (name + '-budget.json')).write_text(json.dumps(budget, indent=2) + '\n')
        if budget['result'] != 'pass':
            raise ValueError(name + ' failed startup/latency budgets: ' + '; '.join(budget['errors']))
        unchanged()
        return {'result': result, 'result_sha256': sha(path), 'budget': budget}

    try:
        save()
        errors = []
        with ThreadPoolExecutor(max_workers=4) as pool:
            futures = {pool.submit(run, job): job[0] for job in jobs}
            for future in as_completed(futures):
                name = futures[future]
                try:
                    report['jobs'][name] = future.result()
                except Exception as error:
                    report['jobs'][name] = {'result': 'fail', 'error': str(error)}
                    errors.append(name + ': ' + str(error))
                save()
        if errors:
            raise ValueError('; '.join(errors))
        unchanged()
        report.update(result='pass', source_disk_unchanged=True)
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        save()


if __name__ == '__main__':
    main()
