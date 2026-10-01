#!/usr/bin/env python3
"""Package the current two-generation i386 QEMU candidate and its evidence."""

import argparse
import gzip
import hashlib
import json
import runpy
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'build/i386-kernel'
FIRST = BASE / 'selfhost-install-capacity-lexfix-kvm'
SECOND = BASE / 'selfhost-install-capacity-lexfix-gen2-kvm'
IDENTITY = BASE / 'generation-identity-capacity-lexfix-kvm/result.json'
OUT = ROOT / 'build/i386-release-current'
FLAT = {'Kernel', 'SysTry', 'TaskContext', 'ExceptContext', 'IrqEntry',
        'ExceptionEntry'}
RETAINED = {'Startup', 'MemoryRuntime', 'FileRuntime', 'ConsoleRuntime',
            'CompilerProbe', 'CompilerRuntime'}


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def passing(path):
    data = json.loads(path.read_text())
    if data.get('result') != 'pass':
        raise ValueError(f'{path}: expected a passing result')
    return data


def workstation(path, cpu):
    data = passing(path)
    expected = (cpu, 8, 513, 576, 'all pixels matched at each checkpoint',
                20, 'shared task heap')
    actual = tuple(data.get(key) for key in
                   ('cpu', 'ram_mib', 'native_commands', 'submitted_lines',
                    'vga', 'document_session_resource_cycles',
                    'document_session_exact_heap_recovery'))
    if actual != expected:
        raise ValueError(f'{path}: incomplete workstation result: {actual}')


def qemu_command(path, cpu, accel, disk, ram=8, target=None):
    argv = json.loads(path.read_text())
    def arg(flag):
        return argv[argv.index(flag) + 1]
    try:
        drives = [argv[i + 1] for i, item in enumerate(argv[:-1])
                  if item == '-drive']
        if ((arg('-cpu'), arg('-accel'), arg('-m')) !=
                (cpu, accel, str(ram)) or
                f'file={disk},format=raw,if=ide' not in drives or
                (target is not None and
                 f'file={target},format=raw,if=ide,index=2' not in drives)):
            raise ValueError('CPU, accelerator, RAM or disk differs')
    except (IndexError, ValueError) as exc:
        raise ValueError(f'{path}: invalid QEMU command: {exc}') from exc


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--first', type=Path, default=FIRST)
    parser.add_argument('--second', type=Path, default=SECOND)
    parser.add_argument('--identity', type=Path, default=IDENTITY)
    parser.add_argument('--out', type=Path, default=OUT)
    args = parser.parse_args()
    first, second = args.first.resolve(), args.second.resolve()
    out = args.out.resolve()
    if out.exists():
        parser.error(f'output already exists: {out}')
    first_disk, second_disk = first / 'target.img', second / 'target.img'
    for disk in (first_disk, second_disk):
        if disk.stat().st_size != 16 * 1024 * 1024:
            raise ValueError(f'{disk}: expected a 16 MiB raw IDE disk')
    first_hash, second_hash = sha256(first_disk), sha256(second_disk)
    identity = passing(args.identity)
    if (identity.get('first_disk_sha256'),
            identity.get('second_disk_sha256'), identity.get('module_count')) != (
            first_hash, second_hash, 12):
        raise ValueError('generation identity does not bind these two disks')
    for key in ('first_volume', 'second_volume'):
        if identity.get(key, {}).get('bitmap') != 'matches reachable extents':
            raise ValueError(f'{key}: RedSea bitmap audit is incomplete')

    evidence = {
        'generation-identity.json': args.identity,
        'first-install.json': first / 'result.json',
        'second-install.json': second / 'result.json',
        'first-instruction-audit.json': first / 'instruction-audit/result.json',
        'second-instruction-audit.json': second / 'instruction-audit/result.json',
        'first-boot.json': first / 'boot/result.json',
        'second-boot.json': second / 'boot/result.json',
        'first-kvm-workstation.json': first / 'full-kvm-retry/result.json',
        'first-no-fpu-workstation.json': first / 'full-tcg-nofpu/result.json',
        'first-writable-session.json': first / 'doldoc-tcg-nofpu/result.json',
        'second-retained-build.json':
            BASE / 'selfhost-install-capacity-lexfix-gen2-retained-build-kvm/result.json',
        'second-retained-install.json':
            BASE / 'selfhost-install-capacity-lexfix-gen2-retained-install-kvm-retry/result.json',
        'first-boot-command.json': first / 'boot/command.json',
        'second-boot-command.json': second / 'boot/command.json',
        'first-build-command.json': first / 'build/command.json',
        'second-build-command.json': second / 'build/command.json',
        'second-retained-build-command.json':
            BASE / 'selfhost-install-capacity-lexfix-gen2-retained-build-kvm/qemu/command.json',
        'second-retained-install-command.json':
            BASE / 'selfhost-install-capacity-lexfix-gen2-retained-install-kvm-retry/replace/command.json',
        'first-kvm-command.json': first / 'full-kvm-retry/command.json',
        'first-no-fpu-command.json': first / 'full-tcg-nofpu/command.json',
        'doldoc-create-command.json': first / 'doldoc-tcg-nofpu/create-edit-save/command.json',
        'doldoc-reopen-command.json': first / 'doldoc-tcg-nofpu/reopen/command.json',
        'doldoc-revised-command.json': first / 'doldoc-tcg-nofpu/revised/command.json',
        'support-matrix.md': ROOT / 'docs/i386-support-matrix.md',
        'acceptance.md': ROOT / 'docs/i386-m7-acceptance.md',
        'manual-workflow.md': ROOT / 'docs/i386-test-workflow.md',
        'manual-observation-template.md':
            ROOT / 'docs/i386-manual-observation-template.md',
    }
    for generation in (first, second):
        install = passing(generation / 'result.json')
        audit = passing(generation / 'instruction-audit/result.json')
        boot = passing(generation / 'boot/result.json')
        if (set(install.get('guest_built_flat_modules', ())) != FLAT or
                set(install.get('guest_built_retained_modules', ())) != RETAINED or
                install.get('flat_sha256') != identity.get('flat_sha256') or
                audit.get('flat_sha256') != identity.get('flat_sha256') or
                set(audit.get('modules', ())) != FLAT | RETAINED or
                audit.get('linked_module_executable_ranges') !=
                '386 instruction allowlist pass' or
                audit.get('installed_payload') != 'matches guest-built flat image' or
                audit.get('filesystem', {}).get('bitmap') !=
                'matches reachable extents' or
                (boot.get('cpu'), boot.get('ram_mib'), boot.get('commands')) !=
                ('486', 8, 2)):
            raise ValueError(f'{generation}: guest build or audit incomplete')
        qemu_command(generation / 'boot/command.json', '486', 'kvm',
                     generation / 'target.img')
        qemu_command(generation / 'build/command.json', '486', 'kvm',
                     generation / 'source.img', 16,
                     generation / 'target.img')
    retained = passing(evidence['second-retained-build.json'])
    replacement = passing(evidence['second-retained-install.json'])
    if (set(retained.get('modules', ())) != RETAINED or
            Path(retained.get('byte_identical_to_installed', '')).resolve() != first_disk or
            set(replacement.get('installed', ())) != RETAINED):
        raise ValueError('second-generation retained build is incomplete')
    qemu_command(evidence['second-retained-build-command.json'], '486', 'kvm',
                 BASE / 'selfhost-install-capacity-lexfix-gen2-retained-build-kvm/source.img', 16)
    qemu_command(evidence['second-retained-install-command.json'], '486', 'kvm',
                 BASE / 'selfhost-install-capacity-lexfix-gen2-retained-install-kvm-retry/candidate.img', 16)
    workstation(first / 'full-kvm-retry/result.json', '486')
    workstation(first / 'full-tcg-nofpu/result.json', '486,-fpu')
    qemu_command(first / 'full-kvm-retry/command.json', '486', 'kvm', first_disk)
    qemu_command(first / 'full-tcg-nofpu/command.json', '486,-fpu', 'tcg', first_disk)
    session = passing(first / 'doldoc-tcg-nofpu/result.json')
    if (session.get('source_disk_sha256') != first_hash or
            session.get('source_disk_unchanged') is not True or
            session.get('after_create_sha256') !=
            sha256(first / 'doldoc-tcg-nofpu/after-create.img') or
            session.get('candidate_sha256') !=
            sha256(first / 'doldoc-tcg-nofpu/session.img') or
            session.get('filesystem_integrity', {}).get('bitmap') !=
            'matches reachable extents'):
        raise ValueError('writable session does not bind the release disk')
    for phase, folder, count in (
            ('create_edit_save', 'create-edit-save', 107),
            ('reopen_after_boot', 'reopen', 56),
            ('revised_after_second_boot', 'revised', 15)):
        result = session.get(phase, {})
        if (result.get('result'), result.get('cpu'), result.get('ram_mib'),
                result.get('commands'), result.get('vga')) != (
                'pass', '486,-fpu', 8, count,
                'all pixels matched at each checkpoint'):
            raise ValueError(f'writable {phase} did not pass')
        qemu_command(first / f'doldoc-tcg-nofpu/{folder}/command.json',
                     '486,-fpu', 'tcg', first / 'doldoc-tcg-nofpu/session.img')

    manifest_path = BASE / 'result.json'
    build = json.loads(manifest_path.read_text())
    sources = build['source_sha256']
    for name, expected in sources.items():
        if sha256(ROOT / name) != expected:
            raise ValueError(f'worktree source differs from build input: {name}')
    read_files = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents']
    delivered = read_files(first_disk, {'/' + name for name in sources})
    if len(delivered) != 814 or any(
            hashlib.sha256(contents).hexdigest() != sources[path[1:]]
            for path, contents in delivered.items()):
        raise ValueError('delivered source differs from current build manifest')
    evidence['build-inputs.json'] = manifest_path
    revision = subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()

    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='i386-current-', dir=out.parent) as temp:
        package = Path(temp) / out.name
        package.mkdir()
        shutil.copyfile(ROOT / 'tools/verify-i386-release.py', package / 'verify.py')
        with first_disk.open('rb') as source, (package / 'TempleOS-i386-gen2.img.gz').open('wb') as raw:
            with gzip.GzipFile(filename='', mode='wb', fileobj=raw,
                               mtime=0, compresslevel=9) as compressed:
                shutil.copyfileobj(source, compressed, 1024 * 1024)
        for name, path in evidence.items():
            target = package / 'evidence' / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(path, target)
        (package / 'README.md').write_text(
            '# TempleOS i386 QEMU candidate\n\n'
            'This 16 MiB IDE image was built and installed by the 32-bit guest. '
            'A second guest generation reproduces all twelve modules, the flat '
            'image and boot area byte for byte. The bundled KVM and no-FPU '
            'workstation results, writable DolDoc result and source manifest '
            'are in evidence/. Verify with python3 verify.py.\n\n'
            'Unpack TempleOS-i386-gen2.img.gz and boot a writable copy using:\n\n'
            'qemu-system-i386 -machine pc -accel tcg -cpu 486,-fpu -m 8 '
            '-nic none -drive file=TempleOS-i386-gen2.img,format=raw,if=ide\n\n'
            'Human manual QEMU observation is deferred; this is a local '
            'candidate, not a published release.\n')
        manifest = {
            'format': 1,
            'image': 'TempleOS-i386-gen2.img',
            'image_bytes': first_disk.stat().st_size,
            'image_sha256': first_hash,
            'second_generation_sha256': second_hash,
            'source_revision': revision,
            'build_input_revision': build['revision'],
            'source_file_count': len(sources),
            'disk_source_file_count': len(delivered),
            'packaging_revision': revision,
            'guest_built_modules': 12,
            'flat_image_sha256': identity['flat_sha256'],
            'boot_area_sha256': identity['boot_area_sha256'],
            'files_sha256': {
                str(path.relative_to(package)): sha256(path)
                for path in sorted(package.rglob('*')) if path.is_file()
            },
        }
        (package / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        package.rename(out)
    print(json.dumps({'result': 'pass', 'package': str(out),
                      'image_sha256': first_hash}, indent=2))


if __name__ == '__main__':
    main()
