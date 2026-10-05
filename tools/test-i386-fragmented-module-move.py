#!/usr/bin/env python3
"""Require a native module move to preserve its extent on a fragmented volume."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import struct

ROOT = Path(__file__).resolve().parents[1]


def entry(image, path):
    block = struct.unpack_from('<q', image, 2048*512+24)[0]
    parts = path.strip('/').split('/')
    for index, part in enumerate(parts):
        size = struct.unpack_from('<q', image, block*512+48)[0]
        found = None
        for offset in range(128, size, 64):
            attr, name, child, length, date = struct.unpack_from('<H38sqqQ', image, block*512+offset)
            if not name.split(b'\0', 1)[0]:
                break
            if not attr & 0x100 and name.split(b'\0', 1)[0].decode() == part:
                found = (attr, child, length, date)
                break
        if found is None:
            return None
        if index == len(parts)-1:
            return found
        if not found[0] & 0x10:
            raise ValueError('Path parent is not a directory')
        block = found[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    sources = [args.disk, Path(__file__), ROOT/'tools/i386-kernel-input.py', ROOT/'tools/build-i386-kernel.py']
    pins = {str(p.resolve()): sha(p) for p in sources}
    report = {'result': 'fail', 'input_sha256': pins,
              'scope': 'Native retained-install fragmentation reproducer and same-extent move; not interrupted-write recovery'}
    candidate = args.out/'candidate.img'
    shutil.copyfile(args.disk, candidate)
    before = candidate.read_bytes()
    path = '/Probe/RetainedConsoleRuntime.t32m'
    target = '/Modules/I386/ConsoleRuntime.t32m'
    original = entry(before, path)
    if not original or original[0] != 0x800:
        raise ValueError('Missing regular native ConsoleRuntime fixture')
    commands = [(f'FileDel("C:/Modules/I386/{name}.t32m")&&FileMove("C:/Probe/Retained{name}.t32m","C:/Modules/I386/{name}.t32m");', ['1'])
                for name in ('Startup', 'MemoryRuntime', 'FileRuntime')]
    commands += [('FileDel("C:/Modules/I386/ConsoleRuntime.t32m");', ['1']),
                 ('FileMove("C:/Probe/RetainedConsoleRuntime.t32m","C:/Modules/I386/ConsoleRuntime.t32m");', ['1'])]
    try:
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(candidate, args.out/'move', snapshot=False, ram_mib=16,
            accel='kvm', startup_check={'status': 'ok', 'answers': [],
                                      'command_timeout': 30, 'commands': commands})
        after = candidate.read_bytes()
        if entry(after, path) is not None or entry(after, target) != original:
            raise ValueError('Move did not preserve source extent and metadata')
        _, block, size, _ = original
        if before[block*512:block*512+size] != after[block*512:block*512+size]:
            raise ValueError('Move changed payload bytes')
        if before[:2048*512] != after[:2048*512]:
            raise ValueError('Move changed boot area')
        report['filesystem'] = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](candidate)
        report.update(result='pass', extent=block, bytes=size)
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == h for p, h in pins.items())
        if not report['inputs_unchanged']:
            report['result'] = 'fail'
        (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
