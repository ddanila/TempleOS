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
    parser.add_argument('--cpu', default='486', help='QEMU CPU model for build and boot')
    parser.add_argument('--cross-retained', action='store_true',
                        help='Development-only flat build with verified cross-built retained inputs; not full self-hosting evidence')
    parser.add_argument('--cross-build', type=Path,
                        help='Isolated cross-build directory for --cross-retained provenance')
    parser.add_argument('--qmp-stdio', action='store_true',
                        help='Use QMP stdio and a writable boot copy where sockets and snapshots are blocked')
    parser.add_argument('--command-timeout', type=int, default=2400,
                        help='Seconds allowed for each guest build/install command')
    args = parser.parse_args()
    if args.cross_build and not args.cross_retained:
        parser.error('--cross-build requires --cross-retained')
    cross_build = args.cross_build.resolve() if args.cross_build else ROOT / 'build/i386-kernel'
    if args.command_timeout <= 0:
        parser.error('--command-timeout must be positive')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
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
    cross_manifest_hash = None
    if args.cross_retained:
        manifest_path = cross_build / 'result.json'
        manifest = json.loads(manifest_path.read_text())
        if hashlib.sha256(original).hexdigest() != manifest.get('disk_sha256'):
            raise ValueError('Development input differs from the current cross-built disk')
        for path, module in retained.items():
            if module != (cross_build / 'exports' / Path(path).name).read_bytes():
                raise ValueError(f'Cross-built retained input differs: {path}')
        for name, digest in manifest['source_sha256'].items():
            if hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != digest:
                raise ValueError(f'Development cross-build source changed: {name}')
        cross_manifest_hash = hashlib.sha256(manifest_path.read_bytes()).hexdigest()
    commands = [(f'I386BuildModule("D:/Kernel/I386/{name}.HC",'
                 f'"D:/Modules/I386/{name}.t32m",TRUE)>0;', ['1'])
                for name in FLAT]
    commands += [(
        'I386BuildBootImage("D:/Modules/I386/Kernel.t32m",'
        '"D:/Modules/I386/","D:/Probe/GuestBoot.bin")>0;', ['1']),
        ('I386InstallBootImage("C:/","D:/","D:/Probe/GuestBoot.bin");', ['1'])]
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    run_input(source, out / 'build', target_disk=target, snapshot=False,
              ram_mib=16, accel=args.accel, cpu=args.cpu,
              qmp_stdio=args.qmp_stdio, startup_timeout=180,
              startup_check={'status': 'ok', 'answers': [],
                             'command_timeout': args.command_timeout,
                             'commands': commands})
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
    if not flat or len(flat) > 960 * 512 - 4096:
        raise ValueError('Guest-linked boot image is missing or oversized')
    expected = (original[:4608] + flat + bytes(960 * 512 - 4096 - len(flat)) +
                original[512 + 960 * 512:BOOT_AREA])
    if target.read_bytes()[:BOOT_AREA] != expected:
        raise ValueError('Installed boot area differs from guest-linked image')
    installed_bytes = target.read_bytes()
    boot_disk = target
    if args.qmp_stdio:
        boot_disk = out / 'boot.img'
        shutil.copyfile(target, boot_disk)
    run_input(boot_disk, out / 'boot', snapshot=not args.qmp_stdio, ram_mib=8,
              accel=args.accel, cpu=args.cpu, qmp_stdio=args.qmp_stdio,
              startup_timeout=180,
              startup_check={'status': 'ok', 'answers': [],
                             'commands': [('6*7;', ['42']),
                                          ('DocAllocationCheck;', ['12'])]})
    if args.qmp_stdio and target.read_bytes() != installed_bytes:
        raise ValueError('Independent boot changed the installed reference disk')
    result = {'result': 'pass', 'flat_bytes': len(flat),
              'flat_sha256': hashlib.sha256(flat).hexdigest(),
              'guest_built_flat_modules': list(FLAT),
              'guest_built_retained_modules': [] if args.cross_retained else list(RETAINED),
              'retained_origin': 'cross-built development inputs' if args.cross_retained else 'guest-built supplied inputs',
              'source_disk_sha256': hashlib.sha256(original).hexdigest(),
              'target_disk_sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
              'cross_build_manifest_sha256': cross_manifest_hash,
              'cpu': args.cpu, 'build_ram_mib': 16, 'boot_ram_mib': 8,
              'scope': 'Development flat-kernel build only; not full M7 self-hosting qualification' if args.cross_retained else 'Guest flat-kernel build with supplied guest-built retained modules'}
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(result)


if __name__ == '__main__':
    main()
