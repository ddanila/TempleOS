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
STYLE_DOCUMENT = (b'$FG,4$red$FG$ plain$BG,1$ blue$BG$ end'
                  b'$IV,1$ inv$IV,0$$UL,1$ under$UL,0$ done\x05')


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


def speaker_output(directory, disk):
    data = passing(directory / 'result.json')
    console = data.get('console_result', {})
    if ((data.get('cpu'), data.get('ram_mib'), data.get('accel'),
         data.get('disk_sha256'), data.get('source_disk_unchanged')) !=
            ('486,-fpu', 8, 'tcg', sha256(disk), True) or
            (console.get('result'), console.get('cpu'), console.get('ram_mib'),
             console.get('disk_sha256'), console.get('boot_mode')) !=
            ('pass', '486,-fpu', 8, sha256(disk), 'interactive') or console.get('groups') != ['sound'] or
            console.get('native_commands') != 4):
        raise ValueError(f'{directory}: incomplete speaker output profile')
    wav = directory / 'speaker.wav'
    if data.get('wav_sha256') != sha256(wav):
        raise ValueError(f'{directory}: speaker waveform differs')
    for key, name in (('checker_sha256', 'test-i386-speaker-output.py'),
                      ('input_runner_sha256', 'i386-kernel-input.py')):
        if data.get(key) != sha256(ROOT / 'tools' / name):
            raise ValueError(f'{directory}: changed audio test: {name}')
    assess = runpy.run_path(str(ROOT / 'tools/test-i386-speaker-output.py'))['assess_wav']
    measured = assess(wav, console.get('audio_emission', {}))
    if measured['result'] != 'pass' or any(data.get(key) != value for key, value in measured.items()):
        raise ValueError(f'{directory}: independent audio check failed')
    command = directory / 'console/command.json'
    qemu_command(command, '486,-fpu', 'tcg', disk)
    argv = json.loads(command.read_text())
    if ('-snapshot' not in argv or argv[argv.index('-machine') + 1] != 'pc,pcspk-audiodev=speaker' or
            argv[argv.index('-audiodev') + 1] !=
            f'wav,id=speaker,path={wav},out.frequency=44100,out.channels=1,out.format=s16'):
        raise ValueError(f'{directory}: invalid speaker capture command')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--first', type=Path, default=FIRST)
    parser.add_argument('--second', type=Path, default=SECOND)
    parser.add_argument('--identity', type=Path, default=IDENTITY)
    parser.add_argument('--out', type=Path, default=OUT)
    parser.add_argument('--first-audio', type=Path,
                        default=ROOT / 'build/i386-speaker-output-gen1-emission')
    parser.add_argument('--second-audio', type=Path,
                        default=ROOT / 'build/i386-speaker-output-gen2-emission')
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
        'first-later-no-fpu-workstation.json':
            first / 'full-pentium3-nofpu-stdio-cli-retry/result.json',
        'first-later-no-fpu-provenance.json':
            first / 'full-pentium3-nofpu-stdio-cli-retry/provenance.json',
        'second-no-fpu-workstation.json':
            second / 'full-tcg-nofpu-stdio-cli/result.json',
        'second-no-fpu-provenance.json':
            second / 'full-tcg-nofpu-stdio-cli/provenance.json',
        'second-later-no-fpu-workstation.json':
            second / 'full-pentium3-nofpu-stdio-cli/result.json',
        'second-later-no-fpu-provenance.json':
            second / 'full-pentium3-nofpu-stdio-cli/provenance.json',
        'first-writable-session.json': first / 'doldoc-tcg-nofpu/result.json',
        'second-writable-session.json':
            second / 'doldoc-tcg-nofpu-stdio/result.json',
        'first-original-document-compatibility.json':
            first / 'doc-compat-current/result.json',
        'first-original-document-native-command.json':
            first / 'doc-compat-current/native/command.json',
        'first-original-document-reader-command.json':
            first / 'doc-compat-current/original/command.json',
        'first-original-document-native.DD':
            first / 'doc-compat-current/overlay/NativeCompat.DD',
        'first-original-document-round-trip.DD':
            first / 'doc-compat-current/original/NativeRoundTrip.DD',
        'second-original-document-compatibility.json':
            second / 'doc-compat-stdio/result.json',
        'second-original-document-native-command.json':
            second / 'doc-compat-stdio/native/command.json',
        'second-original-document-reader-command.json':
            second / 'doc-compat-stdio/original/command.json',
        'second-original-document-native.DD':
            second / 'doc-compat-stdio/overlay/NativeCompat.DD',
        'second-original-document-round-trip.DD':
            second / 'doc-compat-stdio/original/NativeRoundTrip.DD',
        'first-original-style-compatibility.json':
            first / 'doc-style-compat-stdio/result.json',
        'first-original-style-reader-command.json':
            first / 'doc-style-compat-stdio/original/command.json',
        'first-original-style-native.DD':
            first / 'doc-style-compat-stdio/overlay/NativeColor.DD',
        'first-original-style-round-trip.DD':
            first / 'doc-style-compat-stdio/original/OriginalStyleRoundTrip.DD',
        'first-original-authored-style.DD':
            first / 'doc-style-compat-stdio/original/OriginalAuthoredStyle.DD',
        'first-native-style-import-command.json':
            first / 'doc-style-compat-stdio/native-import/command.json',
        'second-original-style-compatibility.json':
            second / 'doc-style-compat-stdio/result.json',
        'second-original-style-reader-command.json':
            second / 'doc-style-compat-stdio/original/command.json',
        'second-original-style-native.DD':
            second / 'doc-style-compat-stdio/overlay/NativeColor.DD',
        'second-original-style-round-trip.DD':
            second / 'doc-style-compat-stdio/original/OriginalStyleRoundTrip.DD',
        'second-original-authored-style.DD':
            second / 'doc-style-compat-stdio/original/OriginalAuthoredStyle.DD',
        'second-native-style-import-command.json':
            second / 'doc-style-compat-stdio/native-import/command.json',
        'first-install-recovery.json': first / 'install-recovery-current-kvm/result.json',
        'second-no-fpu-install-recovery.json':
            second / 'install-recovery-tcg-nofpu-stdio-retry/result.json',
        'second-retained-build.json':
            BASE / 'selfhost-install-capacity-lexfix-gen2-retained-build-kvm/result.json',
        'second-no-fpu-retained-build.json':
            BASE / 'retained-build-capacity-lexfix-gen2-tcg-nofpu-stdio/result.json',
        'second-no-fpu-retained-probe-command.json':
            BASE / 'retained-build-capacity-lexfix-gen2-tcg-nofpu-stdio/compiler-probe-command.json',
        'second-no-fpu-retained-runtime-command.json':
            BASE / 'retained-build-capacity-lexfix-gen2-tcg-nofpu-stdio/compiler-runtime-command.json',
        'second-no-fpu-retained-runtime-trace.log':
            BASE / 'retained-build-capacity-lexfix-gen2-tcg-nofpu-stdio/compiler-runtime-trace.log',
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
        'first-later-no-fpu-command.json':
            first / 'full-pentium3-nofpu-stdio-cli-retry/command.json',
        'second-no-fpu-command.json':
            second / 'full-tcg-nofpu-stdio-cli/command.json',
        'second-later-no-fpu-command.json':
            second / 'full-pentium3-nofpu-stdio-cli/command.json',
        'doldoc-create-command.json': first / 'doldoc-tcg-nofpu/create-edit-save/command.json',
        'doldoc-reopen-command.json': first / 'doldoc-tcg-nofpu/reopen/command.json',
        'doldoc-revised-command.json': first / 'doldoc-tcg-nofpu/revised/command.json',
        'second-doldoc-create-command.json':
            second / 'doldoc-tcg-nofpu-stdio/create-edit-save/command.json',
        'second-doldoc-reopen-command.json':
            second / 'doldoc-tcg-nofpu-stdio/reopen/command.json',
        'second-doldoc-revised-command.json':
            second / 'doldoc-tcg-nofpu-stdio/revised/command.json',
        'support-matrix.md': ROOT / 'docs/i386-support-matrix.md',
        'acceptance.md': ROOT / 'docs/i386-m7-acceptance.md',
        'manual-workflow.md': ROOT / 'docs/i386-test-workflow.md',
        'manual-observation-template.md':
            ROOT / 'docs/i386-manual-observation-template.md',
    }
    for label, audio, disk in (('first', args.first_audio.resolve(), first_disk),
                               ('second', args.second_audio.resolve(), second_disk)):
        speaker_output(audio, disk)
        evidence[f'{label}-speaker-output.json'] = audio / 'result.json'
        evidence[f'{label}-speaker-command.json'] = audio / 'console/command.json'
        evidence[f'{label}-speaker.wav'] = audio / 'speaker.wav'
    evidence['speaker-output-checker.py'] = ROOT / 'tools/test-i386-speaker-output.py'
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
    no_fpu_dir = BASE / 'retained-build-capacity-lexfix-gen2-tcg-nofpu-stdio'
    no_fpu = passing(evidence['second-no-fpu-retained-build.json'])
    if (set(no_fpu.get('modules', ())) != RETAINED or
            Path(no_fpu.get('byte_identical_to_installed', '')).resolve() != second_disk or
            no_fpu.get('source_disk_sha256') != sha256(no_fpu_dir / 'source.img') or
            no_fpu.get('installed_disk_sha256') != second_hash):
        raise ValueError('second-generation no-FPU retained build is incomplete')
    read_files = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents']
    output_modules = read_files(no_fpu_dir / 'source.img',
                                {f'/Probe/Retained{name}.t32m' for name in RETAINED})
    installed_modules = read_files(second_disk,
                                   {f'/Modules/I386/{name}.t32m' for name in RETAINED})
    for name in RETAINED:
        built = output_modules.get(f'/Probe/Retained{name}.t32m')
        if (built is None or built != installed_modules.get(f'/Modules/I386/{name}.t32m') or
                no_fpu['modules'][name].get('bytes') != len(built) or
                no_fpu['modules'][name].get('sha256') != hashlib.sha256(built).hexdigest()):
            raise ValueError(f'no-FPU retained module {name} differs from installed copy')
    for key in ('second-no-fpu-retained-probe-command.json',
                'second-no-fpu-retained-runtime-command.json'):
        command_path = evidence[key]
        qemu_command(command_path, '486,-fpu', 'tcg', no_fpu_dir / 'source.img', 16)
        argv = json.loads(command_path.read_text())
        if ('-snapshot' in argv or '-qmp' not in argv or
                argv[argv.index('-qmp') + 1] != 'stdio'):
            raise ValueError(f'{key}: expected writable QMP stdio run')
    trace = evidence['second-no-fpu-retained-runtime-trace.log'].read_bytes()
    if b'COMMAND OK\n' not in trace or b'\0' in trace:
        raise ValueError('no-FPU compiler runtime trace lacks a completed command')
    qemu_command(evidence['second-retained-install-command.json'], '486', 'kvm',
                 BASE / 'selfhost-install-capacity-lexfix-gen2-retained-install-kvm-retry/candidate.img', 16)
    workstation(first / 'full-kvm-retry/result.json', '486')
    workstation(first / 'full-tcg-nofpu/result.json', '486,-fpu')
    later_dir = first / 'full-pentium3-nofpu-stdio-cli-retry'
    workstation(later_dir / 'result.json', 'pentium3,-fpu')
    later_provenance = json.loads((later_dir / 'provenance.json').read_text())
    if (later_provenance.get('source_disk_sha256') != first_hash or
            later_provenance.get('source_disk_unchanged') is not True or
            later_provenance.get('working_disk') != str(later_dir / 'writable.img')):
        raise ValueError('later-CPU workstation is not bound to release image')
    qemu_command(first / 'full-kvm-retry/command.json', '486', 'kvm', first_disk)
    qemu_command(first / 'full-tcg-nofpu/command.json', '486,-fpu', 'tcg', first_disk)
    qemu_command(later_dir / 'command.json', 'pentium3,-fpu', 'tcg',
                 later_dir / 'writable.img')
    later_argv = json.loads((later_dir / 'command.json').read_text())
    if ('-snapshot' in later_argv or '-qmp' not in later_argv or
            later_argv[later_argv.index('-qmp') + 1] != 'stdio'):
        raise ValueError('later-CPU command did not use the writable stdio profile')
    second_no_fpu = second / 'full-tcg-nofpu-stdio-cli'
    workstation(second_no_fpu / 'result.json', '486,-fpu')
    second_provenance = json.loads((second_no_fpu / 'provenance.json').read_text())
    if (second_provenance.get('source_disk_sha256') != second_hash or
            second_provenance.get('source_disk_unchanged') is not True or
            second_provenance.get('working_disk') !=
            str(second_no_fpu / 'writable.img')):
        raise ValueError('second-generation no-FPU run is not bound to its disk')
    qemu_command(second_no_fpu / 'command.json', '486,-fpu', 'tcg',
                 second_no_fpu / 'writable.img')
    second_argv = json.loads((second_no_fpu / 'command.json').read_text())
    if ('-snapshot' in second_argv or '-qmp' not in second_argv or
            second_argv[second_argv.index('-qmp') + 1] != 'stdio'):
        raise ValueError('second-generation no-FPU command is incomplete')
    second_later = second / 'full-pentium3-nofpu-stdio-cli'
    workstation(second_later / 'result.json', 'pentium3,-fpu')
    later_provenance = json.loads((second_later / 'provenance.json').read_text())
    if (later_provenance.get('source_disk_sha256') != second_hash or
            later_provenance.get('source_disk_unchanged') is not True or
            later_provenance.get('working_disk') !=
            str(second_later / 'writable.img')):
        raise ValueError('second-generation later-CPU run is not bound to its disk')
    qemu_command(second_later / 'command.json', 'pentium3,-fpu', 'tcg',
                 second_later / 'writable.img')
    second_later_argv = json.loads((second_later / 'command.json').read_text())
    if ('-snapshot' in second_later_argv or '-qmp' not in second_later_argv or
            second_later_argv[second_later_argv.index('-qmp') + 1] != 'stdio'):
        raise ValueError('second-generation later-CPU command is incomplete')
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

    second_session_dir = second / 'doldoc-tcg-nofpu-stdio'
    second_session = passing(second_session_dir / 'result.json')
    if (second_session.get('source_disk_sha256') != second_hash or
            second_session.get('source_disk_unchanged') is not True or
            second_session.get('after_create_sha256') !=
            sha256(second_session_dir / 'after-create.img') or
            second_session.get('candidate_sha256') !=
            sha256(second_session_dir / 'session.img') or
            second_session.get('filesystem_integrity', {}).get('bitmap') !=
            'matches reachable extents'):
        raise ValueError('second-generation writable session is incomplete')
    for phase, folder, count in (
            ('create_edit_save', 'create-edit-save', 107),
            ('reopen_after_boot', 'reopen', 56),
            ('revised_after_second_boot', 'revised', 15)):
        outcome = second_session.get(phase, {})
        if (outcome.get('result'), outcome.get('cpu'), outcome.get('ram_mib'),
                outcome.get('commands'), outcome.get('vga')) != (
                'pass', '486,-fpu', 8, count,
                'all pixels matched at each checkpoint'):
            raise ValueError(f'second-generation writable {phase} did not pass')
        command_path = second_session_dir / folder / 'command.json'
        qemu_command(command_path, '486,-fpu', 'tcg',
                     second_session_dir / 'session.img')
        command_argv = json.loads(command_path.read_text())
        if ('-qmp' not in command_argv or
                command_argv[command_argv.index('-qmp') + 1] != 'stdio'):
            raise ValueError(f'second-generation writable {phase} lacks QMP stdio')

    compat = passing(evidence['first-original-document-compatibility.json'])
    native_doc = evidence['first-original-document-native.DD']
    original_doc = evidence['first-original-document-round-trip.DD']
    if (compat.get('source_disk_sha256') != first_hash or
            compat.get('source_unchanged') is not True or
            compat.get('original_round_trip') != 'byte exact' or
            compat.get('bytes') != 37 or
            compat.get('sha256') != sha256(native_doc) or
            native_doc.read_bytes() != original_doc.read_bytes() or
            compat.get('native_run', {}).get('result') != 'pass'):
        raise ValueError('original TempleOS document round trip is incomplete')
    qemu_command(evidence['first-original-document-native-command.json'],
                 '486', 'tcg', first / 'doc-compat-current/native.img')
    original_argv = json.loads(
        evidence['first-original-document-reader-command.json'].read_text())
    if (not original_argv or original_argv[0] != 'qemu-system-x86_64' or
            '-accel' not in original_argv or
            original_argv[original_argv.index('-accel') + 1] != 'tcg'):
        raise ValueError('original TempleOS reader command is incomplete')

    second_compat_dir = second / 'doc-compat-stdio'
    second_compat = passing(second_compat_dir / 'result.json')
    second_native_doc = second_compat_dir / 'overlay/NativeCompat.DD'
    second_original_doc = second_compat_dir / 'original/NativeRoundTrip.DD'
    if (second_compat.get('source_disk_sha256') != second_hash or
            second_compat.get('source_unchanged') is not True or
            second_compat.get('original_round_trip') != 'byte exact' or
            second_compat.get('bytes') != 37 or
            second_compat.get('sha256') != sha256(second_native_doc) or
            second_native_doc.read_bytes() != second_original_doc.read_bytes() or
            second_native_doc.read_bytes() != native_doc.read_bytes() or
            second_compat.get('native_run', {}).get('result') != 'pass'):
        raise ValueError('second-generation original document round trip is incomplete')
    qemu_command(second_compat_dir / 'native/command.json', '486', 'tcg',
                 second_compat_dir / 'native.img')
    second_reader_argv = json.loads(
        (second_compat_dir / 'original/command.json').read_text())
    if (not second_reader_argv or second_reader_argv[0] != 'qemu-system-x86_64' or
            '-accel' not in second_reader_argv or
            second_reader_argv[second_reader_argv.index('-accel') + 1] != 'tcg' or
            '-qmp' not in second_reader_argv or
            second_reader_argv[second_reader_argv.index('-qmp') + 1] != 'stdio'):
        raise ValueError('second-generation original reader command is incomplete')

    for label, generation in (('first', first), ('second', second)):
        style = passing(evidence[f'{label}-original-style-compatibility.json'])
        native_style = evidence[f'{label}-original-style-native.DD']
        original_style = evidence[f'{label}-original-style-round-trip.DD']
        authored_style = evidence[f'{label}-original-authored-style.DD']
        imported_disk = generation / 'doc-style-compat-stdio/native-import.img'
        session = generation / ('doldoc-tcg-nofpu' if label == 'first'
                                else 'doldoc-tcg-nofpu-stdio') / 'session.img'
        if (style.get('session_disk_sha256') != sha256(session) or
                style.get('session_disk_unchanged') is not True or
                style.get('original_round_trip') != 'byte exact' or
                style.get('bytes') != len(STYLE_DOCUMENT) or
                style.get('sha256') != sha256(native_style) or
                native_style.read_bytes() != STYLE_DOCUMENT or
                original_style.read_bytes() != STYLE_DOCUMENT or
                style.get('original_authored_bytes') != len(authored_style.read_bytes()) or
                style.get('original_authored_sha256') != sha256(authored_style) or
                authored_style.read_bytes() != STYLE_DOCUMENT[:-1] + b'!\x05' or
                read_files(imported_disk, {'/NativeColor.DD'}).get(
                    '/NativeColor.DD') != authored_style.read_bytes() or
                style.get('native_import', {}).get('result') != 'pass' or
                style['native_import'].get('cpu') != '486,-fpu' or
                style['native_import'].get('commands') != 5 or
                style['native_import'].get('vga') !=
                    'all pixels matched at each checkpoint'):
            raise ValueError(f'{label} original styled-document round trip is incomplete')
        qemu_command(evidence[f'{label}-native-style-import-command.json'],
                     '486,-fpu', 'tcg', imported_disk)
        native_style_argv = json.loads(
            evidence[f'{label}-native-style-import-command.json'].read_text())
        if ('-qmp' not in native_style_argv or
                native_style_argv[native_style_argv.index('-qmp') + 1] != 'stdio'):
            raise ValueError(f'{label} native style import lacks QMP stdio')
        style_argv = json.loads(
            evidence[f'{label}-original-style-reader-command.json'].read_text())
        if (not style_argv or style_argv[0] != 'qemu-system-x86_64' or
                '-accel' not in style_argv or
                style_argv[style_argv.index('-accel') + 1] != 'tcg' or
                '-qmp' not in style_argv or
                style_argv[style_argv.index('-qmp') + 1] != 'stdio'):
            raise ValueError(f'{label} original style reader command is incomplete')

    recovery_dir = first / 'install-recovery-current-kvm'
    recovery = passing(evidence['first-install-recovery.json'])
    if (recovery.get('source_unchanged') is not True or
            [case.get('cut_lba') for case in recovery.get('cases', ())] !=
            [128, 850] or sha256(recovery_dir / 'source.img') != first_hash):
        raise ValueError('current-image install recovery is incomplete')
    for case in recovery['cases']:
        lba = case['cut_lba']
        folder = recovery_dir / f'cut-lba-{lba}'
        target = folder / 'target.img'
        if (case.get('result') != 'pass' or case.get('lba_zero') != 'blank' or
                case.get('filesystem', {}).get('bitmap') !=
                'matches reachable extents' or
                case.get('retry', {}).get('result') != 'pass' or
                case.get('independent_boot', {}).get('result') != 'pass' or
                sha256(target) != first_hash):
            raise ValueError(f'install recovery at LBA {lba} is incomplete')
        for phase in ('interrupted', 'retry'):
            path = folder / phase / 'command.json'
            qemu_command(path, '486', 'kvm', recovery_dir / 'source.img', 16, target)
            evidence[f'install-recovery-lba-{lba}-{phase}-command.json'] = path
        path = folder / 'independent/command.json'
        qemu_command(path, '486', 'kvm', target, 16)
        evidence[f'install-recovery-lba-{lba}-boot-command.json'] = path
    committed = recovery.get('committed_case', {})
    committed_dir = recovery_dir / 'cut-after-lba-zero'
    committed_target = committed_dir / 'target.img'
    if (committed.get('result') != 'pass' or committed.get('cut_lba') != 0 or
            committed.get('disk') != 'matches complete reference' or
            committed.get('filesystem', {}).get('bitmap') !=
            'matches reachable extents' or
            committed.get('independent_boot', {}).get('result') != 'pass' or
            sha256(committed_target) != first_hash):
        raise ValueError('post-LBA-0 install recovery is incomplete')
    path = committed_dir / 'interrupted/command.json'
    qemu_command(path, '486', 'kvm', recovery_dir / 'source.img', 16,
                 committed_target)
    evidence['install-recovery-lba-0-interrupted-command.json'] = path
    path = committed_dir / 'independent/command.json'
    qemu_command(path, '486', 'kvm', committed_target)
    evidence['install-recovery-lba-0-boot-command.json'] = path

    second_recovery_dir = second / 'install-recovery-tcg-nofpu-stdio-retry'
    second_recovery = passing(evidence['second-no-fpu-install-recovery.json'])
    if (second_recovery.get('source_unchanged') is not True or
            [case.get('cut_lba') for case in second_recovery.get('cases', ())] !=
            [128, 850] or sha256(second_recovery_dir / 'source.img') != second_hash):
        raise ValueError('second-generation no-FPU install recovery is incomplete')
    for case in second_recovery['cases']:
        lba = case['cut_lba']
        folder = second_recovery_dir / f'cut-lba-{lba}'
        target = folder / 'target.img'
        if (case.get('result') != 'pass' or case.get('lba_zero') != 'blank' or
                case.get('filesystem', {}).get('bitmap') !=
                'matches reachable extents' or
                case.get('retry', {}).get('result') != 'pass' or
                case.get('independent_boot', {}).get('result') != 'pass' or
                sha256(target) != second_hash):
            raise ValueError(f'second-generation recovery at LBA {lba} is incomplete')
        for phase in ('interrupted', 'retry'):
            path = folder / phase / 'command.json'
            qemu_command(path, '486,-fpu', 'tcg', second_recovery_dir / 'source.img',
                         16, target)
            evidence[f'second-recovery-lba-{lba}-{phase}-command.json'] = path
        path = folder / 'independent/command.json'
        qemu_command(path, '486,-fpu', 'tcg', folder / 'independent.img', 16)
        evidence[f'second-recovery-lba-{lba}-boot-command.json'] = path
    committed = second_recovery.get('committed_case', {})
    committed_dir = second_recovery_dir / 'cut-after-lba-zero'
    committed_target = committed_dir / 'target.img'
    if (committed.get('result') != 'pass' or committed.get('cut_lba') != 0 or
            committed.get('disk') != 'matches complete reference' or
            committed.get('filesystem', {}).get('bitmap') !=
            'matches reachable extents' or
            committed.get('independent_boot', {}).get('result') != 'pass' or
            sha256(committed_target) != second_hash):
        raise ValueError('second-generation post-LBA-0 recovery is incomplete')
    path = committed_dir / 'interrupted/command.json'
    qemu_command(path, '486,-fpu', 'tcg', second_recovery_dir / 'source.img', 16,
                 committed_target)
    evidence['second-recovery-lba-0-interrupted-command.json'] = path
    path = committed_dir / 'independent/command.json'
    qemu_command(path, '486,-fpu', 'tcg', committed_dir / 'independent.img')
    evidence['second-recovery-lba-0-boot-command.json'] = path

    manifest_path = BASE / 'result.json'
    build = json.loads(manifest_path.read_text())
    sources = build['source_sha256']
    for name, expected in sources.items():
        if sha256(ROOT / name) != expected:
            raise ValueError(f'worktree source differs from build input: {name}')
    delivered = read_files(first_disk, {'/' + name for name in sources})
    if len(delivered) != 814 or any(
            hashlib.sha256(contents).hexdigest() != sources[path[1:]]
            for path, contents in delivered.items()):
        raise ValueError('delivered source differs from current build manifest')
    evidence['build-inputs.json'] = manifest_path
    revision = subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    worktree_dirty = bool(subprocess.check_output(
        ['git', 'status', '--porcelain', '--untracked-files=no'],
        cwd=ROOT, text=True).strip())

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
            'image and boot area byte for byte. The bundled KVM, 486 no-FPU '
            'and later-CPU no-FPU workstation results for both generations, '
            'plus both generations\' writable '
            'DolDoc results, '
            'both generations\' original TempleOS binary-document and '
            'bidirectional styled-document round trips, both generations\' interrupted-install '
            'recovery, a six-module no-FPU guest rebuild and source '
            'manifest, and both generations\' PC-speaker waveforms with off/reset '
            'emission checks '
            'are in evidence/. Verify with python3 verify.py.\n\n'
            'Unpack TempleOS-i386-gen2.img.gz and boot a writable copy using:\n\n'
            'qemu-system-i386 -machine pc -accel tcg -cpu 486,-fpu -m 8 '
            '-nic none -drive file=TempleOS-i386-gen2.img,format=raw,if=ide\n\n'
            'Human QEMU observation is optional exploratory feedback; this is a local '
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
            'packaging_worktree_dirty': worktree_dirty,
            'guest_built_modules': 12,
            'speaker_output_generations': ['first', 'second'],
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
