#!/usr/bin/env python3
"""Guest-build the current flat kernel beside all six guest-built retained modules."""

import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parent.parent
FLAT = ('Kernel', 'SysTry', 'TaskContext', 'ExceptContext', 'IrqEntry', 'ExceptionEntry')
RETAINED = ('Startup', 'MemoryRuntime', 'FileRuntime', 'ConsoleRuntime',
            'CompilerProbe', 'CompilerRuntime')
BOOT_AREA = 2048 * 512


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/retained-install/candidate.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/selfhost-install')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    source = out / 'source.img'
    target = out / 'target.img'
    shutil.copyfile(args.disk, source)
    original = source.read_bytes()
    target.write_bytes(bytes(BOOT_AREA) + original[BOOT_AREA:])
    files = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents']
    retained_paths = {f'/Modules/I386/{name}.t32m' for name in RETAINED}
    retained = files(source, retained_paths)
    if set(retained) != retained_paths:
        raise ValueError('Source disk does not contain all guest-built retained modules')
    commands = [(f'I386BuildModule("D:/Kernel/I386/{name}.HC",'
                 f'"D:/Modules/I386/{name}.t32m",TRUE)>0;', ['1'])
                for name in FLAT]
    commands += [(
        'I386BuildBootImage("D:/Modules/I386/Kernel.t32m",'
        '"D:/Modules/I386/","D:/Probe/GuestBoot.bin")>0;', ['1']),
        ('I386InstallBootImage("C:/","D:/","D:/Probe/GuestBoot.bin");', ['1'])]
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    run_input(source, out / 'build', target_disk=target, snapshot=False,
              ram_mib=16, accel=args.accel, startup_timeout=180,
              startup_check={'status': 'ok', 'answers': [],
                             'command_timeout': 2400, 'commands': commands})
    if source.read_bytes() != original:
        raise ValueError('Self-hosting source disk changed')
    installed = files(target, retained_paths)
    if any(installed[path] != retained[path] for path in retained_paths):
        raise ValueError('A guest-built retained module changed during installation')
    flat_paths = {f'/Modules/I386/{name}.t32m' for name in FLAT}
    flat_modules = files(target, flat_paths)
    if set(flat_modules) != flat_paths:
        raise ValueError('A guest-built flat-kernel module is missing')
    flat = files(target, {'/Probe/GuestBoot.bin'}).get('/Probe/GuestBoot.bin')
    if not flat or len(flat) > 944 * 512 - 4096:
        raise ValueError('Guest-linked boot image is missing or oversized')
    expected = (original[:4608] + flat + bytes(944 * 512 - 4096 - len(flat)) +
                original[512 + 944 * 512:BOOT_AREA])
    if target.read_bytes()[:BOOT_AREA] != expected:
        raise ValueError('Installed boot area differs from guest-linked image')
    run_input(target, out / 'boot', snapshot=True, ram_mib=8,
              accel=args.accel, startup_timeout=180,
              startup_check={'status': 'ok', 'answers': [],
                             'commands': [('6*7;', ['42'])]})
    result = {'result': 'pass', 'flat_bytes': len(flat),
              'flat_sha256': hashlib.sha256(flat).hexdigest(),
              'guest_built_flat_modules': list(FLAT),
              'guest_built_retained_modules': list(RETAINED)}
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(result)


if __name__ == '__main__':
    main()
