#!/usr/bin/env python3
"""Build a multi-page relocation-bearing module inside the native guest."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]
FUNCTIONS = 160


def source_bytes():
    lines = ['public I64 WindowTarget(I64 n){return n+17;}']
    lines += [f'public I64 Window{i:03d}(){{return WindowTarget({i})+WindowTarget({i+1});}}'
              for i in range(FUNCTIONS)]
    return ('\n'.join(lines) + '\n').encode('ascii')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    image, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    inputs = [image, Path(__file__).resolve()] + [ROOT / n for n in
        ('tools/package-i386-native-image.py', 'tools/i386-kernel-input.py',
         'tools/build-i386-kernel.py', 'tools/test-i386-retained-build.py')]
    pins = {str(p): sha(p) for p in inputs}
    source = source_bytes()
    report = {'result': 'running', 'scope': 'Native guest build of a multi-page module with distributed relocations; not a full retained generation',
              'input_sha256': pins, 'fixture_sha256': hashlib.sha256(source).hexdigest()}
    try:
        disk = out / 'working.img'
        report['packaging'] = runpy.run_path(str(ROOT / 'tools/package-i386-native-image.py'))['package'](
            image, disk, additions={'/Probe/WindowUnit.HC': source})
        commands = [('I386BuildModule("C:/Probe/WindowUnit.HC","C:/Probe/WindowUnit.t32m",TRUE)>0;', ['1']),
                    ('6*7;', ['42'])]
        report['behavior'] = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input'](
            disk, out / 'guest', snapshot=False, ram_mib=128, cpu='486,-fpu', accel='tcg',
            qmp_stdio=True, welcome=True,
            startup_check={'status': 'ok', 'answers': [], 'command_timeout': 1800, 'commands': commands})
        files = runpy.run_path(str(ROOT / 'tools/build-i386-kernel.py'))['mutated_file_contents'](
            disk, {'/Probe/WindowUnit.HC', '/Probe/WindowUnit.t32m'})
        if files['/Probe/WindowUnit.HC'] != source:
            raise ValueError('Delivered source differs')
        module = files['/Probe/WindowUnit.t32m']
        count, exports = runpy.run_path(str(ROOT / 'tools/test-i386-retained-build.py'))['exports_of'](module)
        total, code_size, declared, records, _ = struct.unpack_from('<5I', module, 12)
        if total != len(module) or declared != count or code_size <= 8192:
            raise ValueError('Module is not large enough to exercise multiple payload pages')
        expected = {'WindowTarget'} | {f'Window{i:03d}' for i in range(FUNCTIONS)}
        if not expected.issubset(exports):
            raise ValueError('Missing generated function exports')
        patches = []
        for index in range(count):
            kind, offset, _, _ = struct.unpack_from('<4I', module, records + index * 16)
            if kind in (2, 5, 6, 7):
                if offset > code_size - 4 or module[32 + offset:36 + offset] != b'\0' * 4:
                    raise ValueError('Invalid serialized relocation slot')
                patches.append(offset)
        pages = sorted({offset // 4096 for offset in patches})
        if len(patches) < FUNCTIONS or len(pages) < 2:
            raise ValueError('Generated relocations do not cover multiple payload pages')
        (out / 'WindowUnit.t32m').write_bytes(module)
        report.update(result='pass', module_sha256=hashlib.sha256(module).hexdigest(),
                      module_bytes=len(module), code_bytes=code_size, records=count,
                      exports=len(exports), patches=len(patches), patch_pages=pages)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(Path(p).is_file() and sha(Path(p)) == digest for p, digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Execution inputs changed')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
