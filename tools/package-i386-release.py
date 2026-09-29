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


def require_qemu_command(path, cpu, accel, image, ram_mib=8, target=None):
    argv = json.loads(path.read_text())
    def value(flag):
        return argv[argv.index(flag) + 1]
    try:
        if (value('-cpu'), value('-accel'), value('-m')) != (cpu, accel, str(ram_mib)):
            raise ValueError('wrong CPU, accelerator or memory size')
        drives = [argv[index + 1] for index, arg in enumerate(argv[:-1])
                  if arg == '-drive']
        if f'file={image},format=raw,if=ide' not in drives:
            raise ValueError('QEMU command uses a different disk')
        if target is not None and f'file={target},format=raw,if=ide,index=2' not in drives:
            raise ValueError('QEMU command uses a different installation target')
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
    gen3 = base / 'selfhost-install-gen3-tcg-nofpu-long'
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
    gen3_install = read_pass(gen3 / 'result.json')
    gen3_instruction = read_pass(gen3 / 'instruction-audit/result.json')
    gen3_identity = read_pass(base / 'generation-identity-gen2-gen3-tcg-nofpu/result.json')
    gen3_image = gen3 / 'target.img'
    gen3_hash = sha256(gen3_image)
    if (gen3_identity.get('first_disk_sha256') != image_hash or
            gen3_identity.get('second_disk_sha256') != gen3_hash or
            gen3_identity.get('module_count') != 12 or
            gen3_identity.get('flat_sha256') != generation.get('flat_sha256') or
            gen3_identity.get('boot_area_sha256') != generation.get('boot_area_sha256') or
            gen3_install.get('flat_sha256') != generation.get('flat_sha256') or
            gen3_instruction.get('flat_sha256') != generation.get('flat_sha256')):
        raise ValueError('no-FPU guest-built Generation 3 differs from Generation 2')
    gen3_boot = read_pass(gen3 / 'boot/result.json')
    if (gen3_boot.get('cpu'), gen3_boot.get('ram_mib'), gen3_boot.get('commands')) != (
            '486,-fpu', 8, 2):
        raise ValueError('no-FPU Generation 3 independent boot is incomplete')
    require_qemu_command(gen3 / 'build/command.json', '486,-fpu', 'tcg',
                         gen3 / 'source.img', 16, gen3_image)
    require_qemu_command(gen3 / 'boot/command.json', '486,-fpu', 'tcg', gen3_image)
    require_workstation(gen3 / 'full-tcg-nofpu/result.json', '486,-fpu')
    require_qemu_command(gen3 / 'full-tcg-nofpu/command.json',
                         '486,-fpu', 'tcg', gen3_image)
    gen3_session_dir = gen3 / 'doldoc-tcg-nofpu-final'
    gen3_session_path = gen3_session_dir / 'result.json'
    gen3_session = read_pass(gen3_session_path)
    if (gen3_session.get('source_disk_sha256') != gen3_hash or
            not gen3_session.get('source_disk_unchanged') or
            gen3_session.get('after_create_sha256') !=
            sha256(gen3_session_dir / 'after-create.img') or
            gen3_session.get('filesystem_integrity', {}).get('bitmap') !=
            'matches reachable extents'):
        raise ValueError('no-FPU Generation 3 writable session is incomplete')
    for phase, folder, commands in (
            ('create_edit_save', 'create-edit-save', 107),
            ('reopen_after_boot', 'reopen', 56),
            ('revised_after_second_boot', 'revised', 15)):
        phase_result = gen3_session.get(phase, {})
        if (phase_result.get('result'), phase_result.get('cpu'),
                phase_result.get('ram_mib'), phase_result.get('commands'),
                phase_result.get('vga')) != (
                'pass', '486,-fpu', 8, commands,
                'all pixels matched at each checkpoint'):
            raise ValueError(f'no-FPU Generation 3 writable {phase} did not pass')
        require_qemu_command(gen3_session_dir / folder / 'command.json',
                             '486,-fpu', 'tcg', gen3_session_dir / 'session.img')
    console_retained_dir = base / 'retained-console-gen3-tcg-nofpu-long'
    console_retained_path = console_retained_dir / 'result.json'
    console_retained = read_pass(console_retained_path)
    console_module = console_retained.get('modules', {}).get('ConsoleRuntime', {})
    if (set(console_retained.get('modules', {})) != {'ConsoleRuntime'} or
            console_module.get('bytes') != 896448 or
            console_module.get('exports') != 287):
        raise ValueError('no-FPU retained console rebuild is incomplete')
    require_qemu_command(console_retained_dir / 'qemu/command.json',
                         '486,-fpu', 'tcg', console_retained_dir / 'source.img', 16)
    read_redsea_files = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents']
    console_copy = read_redsea_files(
        console_retained_dir / 'source.img', {'/Probe/RetainedConsoleRuntime.t32m'})
    installed_console = read_redsea_files(
        image, {'/Modules/I386/ConsoleRuntime.t32m'})
    if (set(console_copy) != {'/Probe/RetainedConsoleRuntime.t32m'} or
            set(installed_console) != {'/Modules/I386/ConsoleRuntime.t32m'} or
            console_copy['/Probe/RetainedConsoleRuntime.t32m'] !=
            installed_console['/Modules/I386/ConsoleRuntime.t32m']):
        raise ValueError('no-FPU retained console differs from installed module')
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
    doc_compat_dir = gen2 / 'doc-compat-provenance-retry'
    doc_compat_path = doc_compat_dir / 'result.json'
    doc_compat = read_pass(doc_compat_path)
    native_doc = doc_compat_dir / 'overlay/NativeCompat.DD'
    original_doc = doc_compat_dir / 'original/NativeRoundTrip.DD'
    if (doc_compat.get('source_disk_sha256') != image_hash or
            not doc_compat.get('source_unchanged') or
            doc_compat.get('original_round_trip') != 'byte exact' or
            doc_compat.get('bytes') != 37 or
            doc_compat.get('sha256') != sha256(native_doc) or
            native_doc.read_bytes() != original_doc.read_bytes()):
        raise ValueError('original TempleOS did not reproduce the release image document')
    native_run = doc_compat.get('native_run', {})
    if (native_run.get('result'), native_run.get('cpu'), native_run.get('ram_mib'),
            native_run.get('commands'), native_run.get('vga')) != (
            'pass', '486', 8, 2, 'all pixels matched at each checkpoint'):
        raise ValueError('native document compatibility run is incomplete')
    require_qemu_command(doc_compat_dir / 'native/command.json',
                         '486', 'tcg', doc_compat_dir / 'native.img')
    original_command = json.loads((doc_compat_dir / 'original/command.json').read_text())
    if (not original_command or original_command[0] != 'qemu-system-x86_64' or
            '-accel' not in original_command or
            original_command[original_command.index('-accel') + 1] != 'tcg' or
            '-boot' not in original_command or
            original_command[original_command.index('-boot') + 1] != 'd' or
            f'file={doc_compat_dir / "original-reader.iso"},format=raw,media=cdrom,if=ide,index=2'
            not in original_command):
        raise ValueError('original TempleOS document reader command is incomplete')
    recovery_paths = {
        'kvm': gen2 / 'install-recovery-committed',
        'tcg-no-fpu': gen2 / 'install-recovery-tcg-nofpu',
    }
    recovery_artifact_hashes = {}
    recovery_command_paths = {}
    for profile, recovery_dir in recovery_paths.items():
        recovery = read_pass(recovery_dir / 'result.json')
        cpu = '486,-fpu' if profile == 'tcg-no-fpu' else '486'
        accel = 'tcg' if profile == 'tcg-no-fpu' else 'kvm'
        recovery_source = recovery_dir / 'source.img'
        if not recovery.get('source_unchanged') or [case.get('cut_lba') for case in
                recovery.get('cases', [])] != [128, 850]:
            raise ValueError(f'{profile} final-image installation recovery is incomplete')
        for case in recovery['cases']:
            if (case.get('result') != 'pass' or case.get('lba_zero') != 'blank' or
                    case.get('filesystem', {}).get('bitmap') != 'matches reachable extents' or
                    any(case.get(phase, {}).get('result') != 'pass' or
                        case[phase].get('cpu') != cpu for phase in ('retry', 'independent_boot'))):
                raise ValueError(f"{profile} installation recovery failed at LBA {case.get('cut_lba')}")
        committed = recovery.get('committed_case', {})
        if (committed.get('result') != 'pass' or committed.get('cut_lba') != 0 or
                committed.get('disk') != 'matches complete reference' or
                committed.get('filesystem', {}).get('bitmap') != 'matches reachable extents' or
                committed.get('independent_boot', {}).get('result') != 'pass' or
                committed['independent_boot'].get('cpu') != cpu):
            raise ValueError(f'{profile} post-LBA-0 installation hard-stop is incomplete')
        recovery_artifacts = {
            'source': recovery_dir / 'source.img',
            'retry_after_lba_128': recovery_dir / 'cut-lba-128/target.img',
            'retry_after_lba_850': recovery_dir / 'cut-lba-850/target.img',
            'committed_after_lba_zero': recovery_dir / 'cut-after-lba-zero/target.img',
        }
        for name, path in recovery_artifacts.items():
            if sha256(path) != image_hash:
                raise ValueError(f'{profile} {name} differs from the release image')
            recovery_artifact_hashes[f'{profile}_{name}'] = image_hash
        for lba in (128, 850):
            target = recovery_dir / f'cut-lba-{lba}/target.img'
            for phase in ('interrupted', 'retry'):
                key = f'{profile}-lba-{lba}-{phase}'
                command = recovery_dir / f'cut-lba-{lba}/{phase}/command.json'
                require_qemu_command(command, cpu, accel, recovery_source, 16, target)
                recovery_command_paths[key] = command
            key = f'{profile}-lba-{lba}-independent'
            command = recovery_dir / f'cut-lba-{lba}/independent/command.json'
            require_qemu_command(command, cpu, accel, target, 16)
            recovery_command_paths[key] = command
        committed_target = recovery_dir / 'cut-after-lba-zero/target.img'
        command = recovery_dir / 'cut-after-lba-zero/interrupted/command.json'
        require_qemu_command(command, cpu, accel, recovery_source, 16, committed_target)
        recovery_command_paths[f'{profile}-lba-0-interrupted'] = command
        command = recovery_dir / 'cut-after-lba-zero/independent/command.json'
        require_qemu_command(command, cpu, accel, committed_target, 8)
        recovery_command_paths[f'{profile}-lba-0-independent'] = command

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
            'generation-2-to-3-no-fpu-identity.json': base / 'generation-identity-gen2-gen3-tcg-nofpu/result.json',
            'generation-2-install.json': gen2 / 'result.json',
            'generation-3-no-fpu-install.json': gen3 / 'result.json',
            'generation-3-no-fpu-build-command.json': gen3 / 'build/command.json',
            'generation-3-no-fpu-boot.json': gen3 / 'boot/result.json',
            'generation-3-no-fpu-boot-command.json': gen3 / 'boot/command.json',
            'generation-3-no-fpu-instruction-audit.json': gen3 / 'instruction-audit/result.json',
            'generation-3-no-fpu-workstation.json': gen3 / 'full-tcg-nofpu/result.json',
            'generation-3-no-fpu-workstation-command.json': gen3 / 'full-tcg-nofpu/command.json',
            'generation-3-no-fpu-doldoc.json': gen3_session_path,
            'generation-3-no-fpu-retained-console.json': console_retained_path,
            'generation-3-no-fpu-retained-console-command.json': console_retained_dir / 'qemu/command.json',
            'generation-2-instruction-audit.json': gen2 / 'instruction-audit/result.json',
            'generation-2-kvm-workstation.json': gen2 / 'full/result.json',
            'generation-2-kvm-command.json': gen2 / 'full/command.json',
            'generation-2-tcg-no-fpu-workstation.json': gen2 / 'full-tcg-nofpu/result.json',
            'generation-2-tcg-no-fpu-command.json': gen2 / 'full-tcg-nofpu/command.json',
            'generation-2-pentium3-no-fpu-workstation.json': gen2 / 'full-pentium3-nofpu/result.json',
            'generation-2-pentium3-no-fpu-command.json': gen2 / 'full-pentium3-nofpu/command.json',
            'generation-2-tcg-no-fpu-doldoc.json': session_path,
            'generation-2-document-compatibility.json': doc_compat_path,
            'generation-2-document-native-command.json': doc_compat_dir / 'native/command.json',
            'generation-2-document-original-command.json': doc_compat_dir / 'original/command.json',
            'generation-2-document-native.DD': native_doc,
            'generation-2-document-original.DD': original_doc,
            'generation-2-install-recovery.json': recovery_paths['kvm'] / 'result.json',
            'generation-2-tcg-no-fpu-install-recovery.json': recovery_paths['tcg-no-fpu'] / 'result.json',
            'resource-profile.json': resource_path,
            'resource-profile-command.json': gen2 / 'resource-profile/command.json',
            'support-matrix.md': ROOT / 'docs/i386-support-matrix.md',
            'i386-m7-acceptance.md': ROOT / 'docs/i386-m7-acceptance.md',
            'i386-test-workflow.md': ROOT / 'docs/i386-test-workflow.md',
            'i386-manual-observation-template.md': ROOT / 'docs/i386-manual-observation-template.md',
        }
        for name, source in sources.items():
            copy_evidence(source, package / 'evidence' / name)
        for name, source in recovery_command_paths.items():
            copy_evidence(source, package / 'evidence' / f'install-recovery-{name}-command.json')
        for phase in ('create-edit-save', 'reopen', 'revised'):
            copy_evidence(gen3_session_dir / phase / 'command.json', package / 'evidence' /
                          f'generation-3-no-fpu-doldoc-{phase}-command.json')
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
            'A no-FPU TCG guest also built and installed a third generation '
            'with identical modules and boot bytes; its independent boot, '
            'full workstation suite and three writable DolDoc boots pass.\n\n'
            'Unpack with `gzip -dk TempleOS-i386-gen2.img.gz`, then verify the '
            'raw image against `manifest.json`. Boot a writable copy with:\n\n'
            '```sh\nqemu-system-i386 -machine pc -accel tcg -cpu 486,-fpu '
            '-m 8 -nic none -drive file=TempleOS-i386-gen2.img,format=raw,if=ide\n```\n\n'
            'The complete source and reproduction procedure are in the repository. '
            '`source_revision` identifies the committed source whose files match '
            'all build-input hashes; all 814 source files delivered on the disk '
            'also match those hashes. `build_input_revision` is the earlier '
            'cross-build manifest revision, which recorded a dirty worktree. '
            'The bundled document compatibility evidence records original '
            'TempleOS reading and saving a native i386 document byte for byte. '
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
            'recovery_artifact_sha256': recovery_artifact_hashes,
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
