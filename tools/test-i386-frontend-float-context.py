#!/usr/bin/env python3
"""Check conditional frontend helper storage with runtime floating operands."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('I64 FCInteger(I64 a){return a*6;}', []),
    ('FCInteger(7);', ['42']),
    ('F64 FCConvert(I64 a){return a;}', []),
    ('FCConvert(7)==7.0;', ['1']),
    ('I64 FCTruncate(F64 a){return ToI64(a);}', []),
    ('FCTruncate(-7.75)==-7;', ['1']),
    ('F64 FCArithmetic(F64 a,F64 b){return (a+b-a)*b/b;}', []),
    ('FCArithmetic(1.5,2.0)==2.0;', ['1']),
    ('F64 FCUnary(F64 a,F64 b){return Sqrt(a*a)+Abs(b);}', []),
    ('FCUnary(9.0,-2.0)==11.0;', ['1']),
    ('F64 FCMod(F64 a,F64 b){return a%b;}', []),
    ('FCMod(7.5,2.0)==1.5;', ['1']),
    ('F64 FCStatic(){static F64 n=1.25;return n+=0.5;}', []),
    ('FCStatic()==1.75;', ['1']),
    ('FCStatic()==2.25;', ['1']),
    ('FCInteger(7);', ['42']),
]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib', type=int, choices=(8, 16), default=8)
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    manifest_path = disk.parent/'result.json'
    manifest = json.loads(manifest_path.read_text())
    if sha(disk) != manifest['disk_sha256']:
        raise ValueError('Disk differs from its cross-build manifest')
    for name, digest in manifest['source_sha256'].items():
        if name.startswith(('Kernel/', 'Compiler/')) and sha(ROOT/name) != digest:
            raise ValueError(f'Stale candidate source: {name}')
    runner = ROOT/'tools/i386-kernel-input.py'
    if sha(runner) != manifest['build_inputs_sha256']['tools/i386-kernel-input.py']:
        raise ValueError('Input harness differs from cross-build manifest')
    pins = {str(p): sha(p) for p in (disk, manifest_path, runner, Path(__file__))}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(disk, working)
    report = dict(status='running', cpu='486,-fpu', ram_mib=args.ram_mib,
                  scope='Runtime integer/F64 conversion, add/subtract/multiply/divide/modulus, sqrt/abs, comparison and retained static state; not exhaustive IEEE or whole OS acceptance',
                  input_sha256=pins, commands=COMMANDS)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, cpu='486,-fpu',
            ram_mib=args.ram_mib, qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':COMMANDS})
        report['status'] = 'pass'
    except Exception as exc:
        report.update(status='fail', error=str(exc))
        raise
    finally:
        changed = [name for name, digest in pins.items() if sha(Path(name)) != digest]
        if changed:
            report.update(status='fail', error='Test inputs changed', changed_inputs=changed)
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['status'] != 'pass':
        raise RuntimeError(report['error'])
    print('PASS: runtime floating helper context and retained static state')


if __name__ == '__main__':
    main()
