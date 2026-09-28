#!/usr/bin/env python3
"""Build and independently inspect the complete console T32M in a QEMU guest."""

import argparse
import json
from pathlib import Path
import runpy
import shutil
import struct

ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path, default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path, default=ROOT / 'build/i386-kernel/retained-console-build')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    source = out / 'source.img'
    shutil.copyfile(args.disk, source)
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    run_input(source, out / 'qemu', snapshot=False, ram_mib=16, accel=args.accel,
              startup_timeout=180, startup_check={
                  'status': 'ok', 'answers': [], 'command_timeout': 900,
                  'commands': [('I386BuildModule("C:/Kernel/I386/ConsoleRuntime.HC",'
                                '"C:/Probe/RetainedConsole.t32m",TRUE)>0;', ['1'])]})
    files = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents']
    module = files(source, {'/Probe/RetainedConsole.t32m'}).get('/Probe/RetainedConsole.t32m')
    if not module or len(module) < 32 or module[:4] != b'T32M':
        raise ValueError('Guest-built retained console module is absent')
    total, payload, count, records, strings = struct.unpack_from('<5I', module, 12)
    if (total != len(module) or not payload or payload & 7 or
            records != 32 + payload or strings != records + 16 * count or
            strings > total):
        raise ValueError('Guest-built retained console layout is invalid')
    rows = [struct.unpack_from('<4I', module, records + 16 * i) for i in range(count)]
    exports = [module[name:name + length].decode('ascii')
               for kind, offset, name, length in rows if kind == 1]
    required = {'Main', 'ConsoleInit', 'DocExe', 'ExeDoc', 'DocEd',
                'I386BuildModule', 'NativeDocClipPasteAtomicCheck'}
    if not required <= set(exports) or len(set(exports)) != len(exports):
        raise ValueError('Retained console exports are missing or duplicated')
    result = {'result': 'pass', 'bytes': len(module), 'records': count,
              'exports': len(exports), 'required': sorted(required),
              'clip_check_definitions': exports.count('NativeDocClipPasteAtomicCheck')}
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(result)


if __name__ == '__main__':
    main()
