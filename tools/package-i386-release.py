#!/usr/bin/env python3
"""Prepare a locally reviewable i386 image and its QEMU acceptance evidence."""

import argparse
import gzip
import hashlib
import json
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
    for name, expected in build_manifest['source_sha256'].items():
        path = ROOT / name
        if not path.is_file() or sha256(path) != expected:
            raise ValueError(f'build source differs from recorded input: {name}')
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
    require_qemu_command(gen2 / 'full/command.json', '486', 'kvm', image)
    require_qemu_command(gen2 / 'full-tcg-nofpu/command.json', '486,-fpu', 'tcg', image)
    session_path = gen2 / 'doldoc-tcg-nofpu/result.json'
    session = read_pass(session_path)
    if session.get('source_disk_sha256') != image_hash or not session.get('source_disk_unchanged'):
        raise ValueError('writable session did not use the unchanged release image')
    if session.get('filesystem_integrity', {}).get('bitmap') != 'matches reachable extents':
        raise ValueError('writable session lacks RedSea integrity evidence')
    if any(session.get(phase, {}).get('result') != 'pass' for phase in
           ('create_edit_save', 'reopen_after_boot', 'revised_after_second_boot')):
        raise ValueError('writable session did not pass all three boots')
    recovery_path = gen2 / 'install-recovery/result.json'
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

    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='i386-release-', dir=out.parent) as tmp:
        package = Path(tmp) / out.name
        package.mkdir()
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
            'generation-2-tcg-no-fpu-doldoc.json': session_path,
            'generation-2-install-recovery.json': recovery_path,
            'resource-profile.json': base / 'resource-profile-third/resource-result.json',
            'support-matrix.md': ROOT / 'docs/i386-support-matrix.md',
            'test-workflow.md': ROOT / 'docs/i386-test-workflow.md',
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
            'commands are under `evidence/`.\n\n'
            'Unpack with `gzip -dk TempleOS-i386-gen2.img.gz`, then verify the '
            'raw image against `manifest.json`. Boot a writable copy with:\n\n'
            '```sh\nqemu-system-i386 -machine pc -accel tcg -cpu 486,-fpu '
            '-m 8 -nic none -drive file=TempleOS-i386-gen2.img,format=raw,if=ide\n```\n\n'
            'The complete source and reproduction procedure are in the repository '
            'at the manifest revisions. See `evidence/support-matrix.md` for '
            'verified profiles and limits. Human manual acceptance is still open; '
            'this directory is a release candidate, not a published release.\n')
        manifest = {
            'format': 1,
            'image': 'TempleOS-i386-gen2.img',
            'image_bytes': image.stat().st_size,
            'image_sha256': image_hash,
            'build_input_revision': build_manifest['revision'],
            'packaging_revision': revision,
            'guest_built_modules': 12,
            'flat_image_sha256': generation['flat_sha256'],
            'boot_area_sha256': generation['boot_area_sha256'],
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
