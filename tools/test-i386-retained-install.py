#!/usr/bin/env python3
"""Replace retained modules with guest-built copies and boot the result in QEMU."""

import argparse
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parent.parent
MODULES = ('Startup', 'MemoryRuntime', 'FileRuntime', 'ConsoleRuntime',
           'CompilerProbe', 'CompilerRuntime')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path,
                        default=ROOT / 'build/i386-kernel/retained-build/source.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/retained-install')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    candidate = out / 'candidate.img'
    shutil.copyfile(args.source, candidate)
    files = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents']
    source_paths = {f'/Probe/Retained{name}.t32m' for name in MODULES}
    built = files(candidate, source_paths)
    if set(built) != source_paths:
        raise ValueError(f'Missing guest-built retained modules: {source_paths - set(built)}')
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    commands = [(f'FileDel("C:/Modules/I386/{name}.t32m")&&'
                 f'FileMove("C:/Probe/Retained{name}.t32m",'
                 f'"C:/Modules/I386/{name}.t32m");', ['1'])
                for name in MODULES]
    run_input(candidate, out / 'replace', snapshot=False, ram_mib=16,
              accel=args.accel, startup_timeout=180, startup_check={
                  'status': 'ok', 'answers': [], 'command_timeout': 240,
                  'commands': commands})
    installed_paths = {f'/Modules/I386/{name}.t32m' for name in MODULES}
    installed = files(candidate, installed_paths | source_paths)
    if source_paths & set(installed) or set(installed) != installed_paths:
        raise ValueError('Retained replacement left a source copy or lost an installed module')
    for name in MODULES:
        if (installed[f'/Modules/I386/{name}.t32m'] !=
                built[f'/Probe/Retained{name}.t32m']):
            raise ValueError(f'{name} changed while installing')
    run_input(candidate, out / 'boot', snapshot=True, ram_mib=8,
              accel=args.accel, startup_timeout=180, startup_check={
                  'status': 'ok', 'answers': [],
                  'commands': [('6*7;', ['42']),
                               ('DocAllocationCheck;', ['12'])]})
    result = {'result': 'pass', 'installed': list(MODULES),
              'module_bytes': {name: len(built[f'/Probe/Retained{name}.t32m'])
                               for name in MODULES}}
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(result)


if __name__ == '__main__':
    main()
