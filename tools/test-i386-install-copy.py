#!/usr/bin/env python3
"""Verify guest disk publication and an independent boot from its target."""
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
    disk = BUILD / 'kernel.img'
    exports = BUILD / 'exports'
    out = BUILD / 'install-copy'
    out.mkdir(parents=True, exist_ok=True)
    source = bytearray(disk.read_bytes())
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
    result = {'result': 'pass', 'source_sha256': hashlib.sha256(current).hexdigest(),
              'target_sha256': hashlib.sha256(installed).hexdigest(),
              'boots': ['guest-copy', 'independent-target']}
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
