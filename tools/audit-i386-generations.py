#!/usr/bin/env python3
"""Compare two independently installed, fully guest-built i386 generations."""

import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parent.parent
BOOT_AREA = 2048 * 512


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--first', type=Path,
                        default=ROOT / 'build/i386-kernel/selfhost-install-fixed/target.img')
    parser.add_argument('--second', type=Path,
                        default=ROOT / 'build/i386-kernel/selfhost-install-gen2-fixed/target.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/generation-identity')
    args = parser.parse_args()
    build = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))
    paths = {f'/Modules/I386/{name}.t32m' for name in build['DISK_MODULES']}
    paths.add('/Probe/GuestBoot.bin')
    files = build['mutated_file_contents']
    first = files(args.first, paths)
    second = files(args.second, paths)
    if set(first) != paths or set(second) != paths:
        raise ValueError('A generation is missing a guest-built module or flat image')
    if any(first[path] != second[path] for path in paths):
        raise ValueError('Guest-built generation artifacts are not byte-identical')
    first_disk = args.first.read_bytes()
    second_disk = args.second.read_bytes()
    if first_disk[:BOOT_AREA] != second_disk[:BOOT_AREA]:
        raise ValueError('Installed boot areas differ across generations')
    first_volume = build['verify_mutated_volume'](args.first)
    second_volume = build['verify_mutated_volume'](args.second)
    result = {'result': 'pass', 'module_count': len(paths) - 1,
              'flat_bytes': len(first['/Probe/GuestBoot.bin']),
              'flat_sha256': hashlib.sha256(first['/Probe/GuestBoot.bin']).hexdigest(),
              'boot_area_sha256': hashlib.sha256(first_disk[:BOOT_AREA]).hexdigest(),
              'first_volume': first_volume, 'second_volume': second_volume,
              'first_disk_sha256': hashlib.sha256(first_disk).hexdigest(),
              'second_disk_sha256': hashlib.sha256(second_disk).hexdigest()}
    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(result)


if __name__ == '__main__':
    main()
