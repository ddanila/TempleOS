#!/usr/bin/env python3
"""Prepare a locally reviewable i386 image and its QEMU acceptance evidence."""

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
DEFAULT_IMAGE = ROOT / 'build/i386-kernel/selfhost-install-gen2-fixed/target.img'
DEFAULT_OUT = ROOT / 'build/i386-release-candidate'


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def read_pass(path):
    data = json.loads(path.read_text())
    if data.get('result') != 'pass':
        raise ValueError(f'{path}: expected a passing result')
    return data


def require_workstation(path, cpu):
    data = read_pass(path)
    if (data.get('cpu'), data.get('ram_mib'), data.get('native_commands'),
            data.get('submitted_lines'), data.get('vga'),
            data.get('document_session_resource_cycles')) != (
            cpu, 8, 506, 569, 'all pixels matched at each checkpoint', 20):
        raise ValueError(f'{path}: incomplete workstation acceptance')
    return data


def require_qemu_command(path, cpu, accel, image):
    argv = json.loads(path.read_text())
    def value(flag):
        return argv[argv.index(flag) + 1]
    try:
        if (value('-cpu'), value('-accel'), value('-m')) != (cpu, accel, '8'):
            raise ValueError('wrong CPU, accelerator or memory size')
        if f'file={image},format=raw,if=ide' not in value('-drive'):
            raise ValueError('QEMU command uses a different disk')
    except (ValueError, IndexError) as exc:
        raise ValueError(f'{path}: invalid QEMU command: {exc}') from exc


def copy_evidence(source, dest):
    if not source.is_file():
        raise FileNotFoundError(source)
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, dest)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', type=Path, default=DEFAULT_IMAGE)
    parser.add_argument('--out', type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()
    image = args.image.resolve()
    out = args.out.resolve()
    if out.exists():
        parser.error(f'output already exists: {out}')
    if not image.is_file() or image.stat().st_size != 16 * 1024 * 1024:
        parser.error('expected the 16 MiB Generation 2 raw disk image')
    image_hash = sha256(image)

    base = ROOT / 'build/i386-kernel'
    gen2 = base / 'selfhost-install-gen2-fixed'
    build_manifest_path = base / 'result.json'
    build_manifest = json.loads(build_manifest_path.read_text())
    source_paths = list(build_manifest['source_sha256'])
    for name, expected in build_manifest['source_sha256'].items():
        path = ROOT / name
        if not path.is_file() or sha256(path) != expected:
            raise ValueError(f'build source differs from recorded input: {name}')
    source_revision = subprocess.check_output(
        ['git', 'log', '-1', '--format=%H', '--', *source_paths],
        cwd=ROOT, text=True).strip()
    if not source_revision or subprocess.run(
            ['git', 'diff', '--quiet', 'HEAD', '--', *source_paths],
            cwd=ROOT, check=False).returncode or subprocess.run(
            ['git', 'diff', '--quiet', f'{source_revision}..HEAD', '--', *source_paths],
            cwd=ROOT, check=False).returncode:
        raise ValueError('Recorded build sources are not a clean committed source tree')
    disk_files = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents'](
        image, {'/' + name for name in source_paths})
    if len(disk_files) != 814:
        raise ValueError(f'Expected 814 delivered source files, found {len(disk_files)}')
    for path, contents in disk_files.items():
        if hashlib.sha256(contents).hexdigest() != build_manifest['source_sha256'][path[1:]]:
            raise ValueError(f'Delivered source differs from committed source: {path}')
    generation = read_pass(base / 'generation-identity-fixed/result.json')
    if generation.get('second_disk_sha256') != image_hash or generation.get('module_count') != 12:
        raise ValueError('image differs from audited Generation 2 disk')
    install = read_pass(gen2 / 'result.json')
    instruction = read_pass(gen2 / 'instruction-audit/result.json')
    if len({install.get('flat_sha256'), instruction.get('flat_sha256'),
            generation.get('flat_sha256')}) != 1:
        raise ValueError('guest-built flat image hashes disagree')
    require_workstation(gen2 / 'full/result.json', '486')
    require_workstation(gen2 / 'full-tcg-nofpu/result.json', '486,-fpu')
    require_workstation(gen2 / 'full-pentium3-nofpu/result.json', 'pentium3,-fpu')
    require_qemu_command(gen2 / 'full/command.json', '486', 'kvm', image)
    require_qemu_command(gen2 / 'full-tcg-nofpu/command.json', '486,-fpu', 'tcg', image)
    require_qemu_command(gen2 / 'full-pentium3-nofpu/command.json',
                         'pentium3,-fpu', 'tcg', image)
    resource_path = gen2 / 'resource-profile/resource-result.json'
    resource = read_pass(resource_path)
    if (resource.get('cpu'), resource.get('ram_mib'),
            resource.get('document_development_cycles'),
            resource.get('arena_bytes'), resource.get('temporary_live_growth')) != (
            '486,-fpu', 8, 20, 7143424, 3616):
        raise ValueError('final-image 8 MiB resource profile is incomplete')
    require_qemu_command(gen2 / 'resource-profile/command.json',
                         '486,-fpu', 'kvm', image)
    session_path = gen2 / 'doldoc-tcg-nofpu/result.json'
    session = read_pass(session_path)
    if session.get('source_disk_sha256') != image_hash or not session.get('source_disk_unchanged'):
        raise ValueError('writable session did not use the unchanged release image')
    if session.get('filesystem_integrity', {}).get('bitmap') != 'matches reachable extents':
        raise ValueError('writable session lacks RedSea integrity evidence')
    if any(session.get(phase, {}).get('result') != 'pass' for phase in
           ('create_edit_save', 'reopen_after_boot', 'revised_after_second_boot')):
        raise ValueError('writable session did not pass all three boots')
    recovery_path = gen2 / 'install-recovery-committed/result.json'
    recovery = read_pass(recovery_path)
    if not recovery.get('source_unchanged') or [case.get('cut_lba') for case in
            recovery.get('cases', [])] != [128, 850]:
        raise ValueError('final-image installation recovery is incomplete')
    for case in recovery['cases']:
        if (case.get('result') != 'pass' or case.get('lba_zero') != 'blank' or
                case.get('filesystem', {}).get('bitmap') != 'matches reachable extents' or
                case.get('retry', {}).get('result') != 'pass' or
                case.get('independent_boot', {}).get('result') != 'pass'):
            raise ValueError(f"installation recovery failed at LBA {case.get('cut_lba')}")
    committed = recovery.get('committed_case', {})
    if (committed.get('result') != 'pass' or committed.get('cut_lba') != 0 or
            committed.get('disk') != 'matches complete reference' or
            committed.get('filesystem', {}).get('bitmap') != 'matches reachable extents' or
            committed.get('independent_boot', {}).get('result') != 'pass'):
        raise ValueError('post-LBA-0 installation hard-stop is incomplete')
    recovery_artifacts = {
        'source': gen2 / 'install-recovery-committed/source.img',
        'retry_after_lba_128': gen2 / 'install-recovery-committed/cut-lba-128/target.img',
        'retry_after_lba_850': gen2 / 'install-recovery-committed/cut-lba-850/target.img',
        'committed_after_lba_zero': gen2 / 'install-recovery-committed/cut-after-lba-zero/target.img',
    }
    for name, path in recovery_artifacts.items():
        if sha256(path) != image_hash:
            raise ValueError(f'{name} differs from the release image')

    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='i386-release-', dir=out.parent) as tmp:
        package = Path(tmp) / out.name
        package.mkdir()
        shutil.copyfile(ROOT / 'tools/verify-i386-release.py', package / 'verify.py')
        disk_gz = package / 'TempleOS-i386-gen2.img.gz'
        with image.open('rb') as src, disk_gz.open('wb') as raw:
            with gzip.GzipFile(filename='', mode='wb', fileobj=raw, mtime=0, compresslevel=9) as zipped:
                shutil.copyfileobj(src, zipped, 1024 * 1024)
        expanded_hash = hashlib.sha256()
        with gzip.open(disk_gz, 'rb') as expanded:
            for chunk in iter(lambda: expanded.read(1024 * 1024), b''):
                expanded_hash.update(chunk)
        if expanded_hash.hexdigest() != image_hash:
            raise ValueError('compressed release image failed round-trip verification')
        sources = {
            'build-inputs.json': build_manifest_path,
            'generation-identity.json': base / 'generation-identity-fixed/result.json',
            'generation-2-install.json': gen2 / 'result.json',
            'generation-2-instruction-audit.json': gen2 / 'instruction-audit/result.json',
            'generation-2-kvm-workstation.json': gen2 / 'full/result.json',
            'generation-2-kvm-command.json': gen2 / 'full/command.json',
            'generation-2-tcg-no-fpu-workstation.json': gen2 / 'full-tcg-nofpu/result.json',
            'generation-2-tcg-no-fpu-command.json': gen2 / 'full-tcg-nofpu/command.json',
            'generation-2-pentium3-no-fpu-workstation.json': gen2 / 'full-pentium3-nofpu/result.json',
            'generation-2-pentium3-no-fpu-command.json': gen2 / 'full-pentium3-nofpu/command.json',
            'generation-2-tcg-no-fpu-doldoc.json': session_path,
            'generation-2-install-recovery.json': recovery_path,
            'resource-profile.json': resource_path,
            'resource-profile-command.json': gen2 / 'resource-profile/command.json',
            'support-matrix.md': ROOT / 'docs/i386-support-matrix.md',
            'i386-m7-acceptance.md': ROOT / 'docs/i386-m7-acceptance.md',
            'i386-test-workflow.md': ROOT / 'docs/i386-test-workflow.md',
            'i386-manual-observation-template.md': ROOT / 'docs/i386-manual-observation-template.md',
        }
        for name, source in sources.items():
            copy_evidence(source, package / 'evidence' / name)
        for command in sorted(session_path.parent.glob('*/command.json')):
            copy_evidence(command, package / 'evidence' /
                          f'doldoc-{command.parent.name}-command.json')
        revision = subprocess.check_output(
            ['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
        (package / 'README.md').write_text(
            '# TempleOS i386 Generation 2 QEMU candidate\n\n'
            'This 16 MiB raw IDE image was built and installed inside the i386 guest. '
            'The second guest generation reproduces all twelve modules, the flat '
            'kernel and the boot area byte for byte. Evidence and exact QEMU '
            'commands are under `evidence/`. Verify the package first with '
            '`python3 verify.py`.\n\n'
            'Unpack with `gzip -dk TempleOS-i386-gen2.img.gz`, then verify the '
            'raw image against `manifest.json`. Boot a writable copy with:\n\n'
            '```sh\nqemu-system-i386 -machine pc -accel tcg -cpu 486,-fpu '
            '-m 8 -nic none -drive file=TempleOS-i386-gen2.img,format=raw,if=ide\n```\n\n'
            'The complete source and reproduction procedure are in the repository. '
            '`source_revision` identifies the committed source whose files match '
            'all build-input hashes; all 814 source files delivered on the disk '
            'also match those hashes. `build_input_revision` is the earlier '
            'cross-build manifest revision, which recorded a dirty worktree. '
            'See `evidence/i386-m7-acceptance.md` '
            'for the gate status and `evidence/support-matrix.md` for verified '
            'profiles and limits. Use '
            '`evidence/i386-manual-observation-template.md` to record the human '
            'workstation session. Human manual acceptance is still open; '
            'this directory is a release candidate, not a published release.\n')
        manifest = {
            'format': 1,
            'image': 'TempleOS-i386-gen2.img',
            'image_bytes': image.stat().st_size,
            'image_sha256': image_hash,
            'build_input_revision': build_manifest['revision'],
            'build_input_worktree_dirty': build_manifest['worktree_dirty'],
            'source_revision': source_revision,
            'source_file_count': len(source_paths),
            'disk_source_file_count': len(disk_files),
            'packaging_revision': revision,
            'guest_built_modules': 12,
            'flat_image_sha256': generation['flat_sha256'],
            'boot_area_sha256': generation['boot_area_sha256'],
            'recovery_artifact_sha256': {name: image_hash for name in recovery_artifacts},
            'files_sha256': {
                str(path.relative_to(package)): sha256(path)
                for path in sorted(package.rglob('*')) if path.is_file()
            },
        }
        (package / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        package.rename(out)
    print(json.dumps({'result': 'pass', 'package': str(out),
                      'image_sha256': image_hash, 'manifest': str(out / 'manifest.json')}, indent=2))


if __name__ == '__main__':
    main()
