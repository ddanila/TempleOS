#!/usr/bin/env python3
"""Build selected retained T32Ms in QEMU and audit their persisted disk copies."""

import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import struct

ROOT = Path(__file__).resolve().parent.parent
MODULES = ('Startup', 'MemoryRuntime', 'FileRuntime', 'ConsoleRuntime',
           'CompilerProbe', 'CompilerRuntime')


def exports_of(module):
    if not module or len(module) < 32 or module[:4] != b'T32M':
        raise ValueError('Missing or malformed retained module')
    total, payload, count, records, strings = struct.unpack_from('<5I', module, 12)
    if (total != len(module) or not payload or payload & 7 or
            records != 32 + payload or strings != records + 16 * count or
            strings > total):
        raise ValueError('Invalid retained module layout')
    exports = []
    for index in range(count):
        kind, offset, name, length = struct.unpack_from('<4I', module, records + 16 * index)
        if kind not in (4, 6) and (name < strings or length < 1 or name + length > total):
            raise ValueError('Invalid retained module record name')
        if kind == 1:
            if offset >= payload:
                raise ValueError('Retained export lies outside payload')
            exports.append(module[name:name + length].decode('ascii'))
    if len(exports) != len(set(exports)):
        raise ValueError('Duplicate retained module export')
    return count, exports


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def check_console_alloc_wrappers(module):
    _, payload, count, records, _ = struct.unpack_from('<5I', module, 12)
    rows = [struct.unpack_from('<4I', module, records + 16 * i) for i in range(count)]
    exports = sorted((offset, module[name:name + length].decode('ascii'))
                     for kind, offset, name, length in rows if kind == 1)
    index = next(i for i, (_, name) in enumerate(exports)
                 if name == 'NativeDocRecordLoadCore')
    start = exports[index][0]
    end = exports[index + 1][0] if index + 1 < len(exports) else payload
    calls = [module[name:name + length].decode('ascii')
             for kind, offset, name, length in rows
             if kind == 2 and start <= offset < end]
    if calls.count('NativeDocCAlloc') != 4 or calls.count('NativeDocMAlloc') != 1:
        raise ValueError('Guest-built document loader bypasses allocation wrappers')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path, default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path, default=ROOT / 'build/i386-kernel/retained-build')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    parser.add_argument('--cpu', default='486', help='QEMU CPU model for the build boot')
    parser.add_argument('--qmp-stdio', action='store_true',
                        help='Use QMP stdio where Unix sockets are blocked')
    parser.add_argument('--module', choices=MODULES, action='append', dest='modules')
    parser.add_argument('--command-timeout', type=int, default=3600)
    parser.add_argument('--resume', action='store_true',
                        help='Build selected modules on an existing output source.img')
    parser.add_argument('--audit-only', action='store_true',
                        help='Audit the source.img produced by an earlier build')
    parser.add_argument('--compare-installed', type=Path,
                        help='Require guest output to match installed T32Ms on this disk')
    args = parser.parse_args()
    if args.resume and args.audit_only:
        parser.error('--resume and --audit-only cannot be combined')
    selected = tuple(args.modules or MODULES)
    if len(selected) != len(set(selected)):
        parser.error('Each module may be selected only once')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    source = out / 'source.img'
    if not args.audit_only:
        if args.resume:
            if not source.is_file():
                parser.error(f'cannot resume without {source}')
        else:
            shutil.copyfile(args.disk, source)
        commands = [(f'I386BuildModule("C:/Kernel/I386/{name}.HC",'
                     f'"C:/Probe/Retained{name}.t32m",TRUE)>0;', ['1'])
                    for name in selected]
        run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
        run_input(source, out / 'qemu', snapshot=False, ram_mib=16, accel=args.accel,
                  cpu=args.cpu, qmp_stdio=args.qmp_stdio,
                  startup_timeout=180, startup_check={
                      'status': 'ok', 'answers': [],
                      'command_timeout': args.command_timeout, 'commands': commands})
    files = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents']
    wanted = {f'/Probe/Retained{name}.t32m' for name in selected}
    actual = files(source, wanted)
    comparison = None
    if args.compare_installed:
        installed_paths = {f'/Modules/I386/{name}.t32m' for name in selected}
        comparison = files(args.compare_installed, installed_paths)
    result = {'result': 'pass', 'source_disk_sha256': sha256(source),
              'modules': {}}
    for name in selected:
        path = f'/Probe/Retained{name}.t32m'
        module = actual.get(path)
        count, exports = exports_of(module)
        host = (ROOT / f'build/i386-kernel/exports/{name}.t32m').read_bytes()
        _, host_exports = exports_of(host)
        missing = set(host_exports) - set(exports)
        extra = set(exports) - set(host_exports)
        if name == 'CompilerRuntime':
            missing -= {'_I386_DIV_BEGIN', '_I386_DIV_END'}
        if missing or extra:
            raise ValueError(f'{name} export set differs from cross-built module')
        if name == 'ConsoleRuntime':
            check_console_alloc_wrappers(module)
        if comparison is not None and module != comparison.get(
                f'/Modules/I386/{name}.t32m'):
            raise ValueError(f'{name} differs from installed comparison module')
        result['modules'][name] = {'bytes': len(module), 'records': count,
                                   'exports': len(exports),
                                   'sha256': hashlib.sha256(module).hexdigest()}
    if comparison is not None:
        result['byte_identical_to_installed'] = str(args.compare_installed)
        result['installed_disk_sha256'] = sha256(args.compare_installed)
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(result)


if __name__ == '__main__':
    main()
