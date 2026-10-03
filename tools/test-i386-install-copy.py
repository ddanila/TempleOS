#!/usr/bin/env python3
"""Verify guest disk publication and an independent boot from its target."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build/i386-kernel'
spec = importlib.util.spec_from_file_location('i386_build', ROOT / 'tools/build-i386-kernel.py')
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)


def boot(image, output, target=None):
    output.mkdir(parents=True, exist_ok=True)
    cmd = [sys.executable, str(ROOT / 'tools/guest-run.py'), str(image),
           '--i386-disk', '--out', str(output), '--timeout', '1200']
    if target is not None:
        cmd += ['--target-disk', str(target)]
    with (output / 'runner.log').open('w') as log:
        subprocess.run(cmd, cwd=ROOT, stdout=log, stderr=log, check=True)
    return (output / 'debug.log').read_text()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', type=Path, default=BUILD,
                        help='Matching kernel image and exports directory')
    args = parser.parse_args()
    source_build = args.build.resolve()
    disk = source_build / 'kernel.img'
    exports = source_build / 'exports'
    out = source_build / 'install-copy'
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    source = bytearray(disk.read_bytes())
    input_hash = hashlib.sha256(source).hexdigest()
    flags = ('kernel_install_copy_probe',)
    offsets = [build.kernel_flag_disk_offset(exports, flag) for flag in flags]
    if len(source) != 16 * 1024 * 1024 or len(set(offsets)) != len(offsets) or \
            any(struct.unpack_from('<I', source, offset)[0] for offset in offsets):
        raise ValueError('Invalid source image or installer flags')
    for offset in offsets:
        struct.pack_into('<I', source, offset, 1)
    candidate = out / 'source.img'
    target = out / 'target.img'
    candidate.write_bytes(source)
    target.write_bytes(bytes(len(source)))
    first = boot(candidate, out / 'copy-boot', target)
    if first.count('INSTALL COPY READY\n') != 1 or \
            first.count('DONE native kernel startup\n') != 1:
        raise ValueError('Guest installer did not publish its target')
    installed = target.read_bytes()
    current = candidate.read_bytes()
    if installed != current:
        raise ValueError('Installed disk differs from guest source disk')
    second = boot(target, out / 'target-boot')
    if second.count('INSTALL COPY NO TARGET\n') != 1 or \
            second.count('DONE native kernel startup\n') != 1:
        raise ValueError('Installed disk did not boot independently')
    if target.read_bytes() != installed:
        raise ValueError('Independent boot changed the installed disk')
    interrupted = []
    for stop_after in (8192, 32768):
        case = out / f'interrupt-{stop_after}'
        case.mkdir(exist_ok=True)
        interrupted_source = bytearray(source)
        struct.pack_into('<I', interrupted_source, offsets[0], stop_after)
        candidate = case / 'source.img'
        target = case / 'target.img'
        candidate.write_bytes(interrupted_source)
        target.write_bytes(bytes(len(source)))
        report = boot(candidate, case / 'interrupt-boot', target)
        if report.count('INSTALL COPY INTERRUPTED\n') != 1 or \
                report.count('DONE native kernel startup\n') != 1:
            raise ValueError(f'Guest did not interrupt after sector {stop_after}')
        partial = target.read_bytes()
        expected = bytearray(len(source))
        expected[512:min(stop_after + 1, 32768) * 512] = \
            interrupted_source[512:min(stop_after + 1, 32768) * 512]
        if partial != expected or candidate.read_bytes() != interrupted_source:
            raise ValueError(f'Interrupted copy changed unexpected sectors at {stop_after}')
        struct.pack_into('<I', interrupted_source, offsets[0], 1)
        candidate.write_bytes(interrupted_source)
        retry = boot(candidate, case / 'retry-boot', target)
        if retry.count('INSTALL COPY READY\n') != 1 or \
                retry.count('DONE native kernel startup\n') != 1 or \
                target.read_bytes() != interrupted_source:
            raise ValueError(f'Interrupted copy did not recover at {stop_after}')
        interrupted.append({'stop_after_sector': stop_after, 'recovered': True})
    if hashlib.sha256(disk.read_bytes()).hexdigest() != input_hash:
        raise ValueError('Install-copy test changed its input kernel image')
    result = {'result': 'pass', 'source_build_directory': str(source_build),
              'source_input_sha256': input_hash, 'source_input_unchanged': True,
              'source_sha256': hashlib.sha256(current).hexdigest(),
              'target_sha256': hashlib.sha256(installed).hexdigest(),
              'boots': ['guest-copy', 'independent-target'],
              'interrupted_cases': interrupted}
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
