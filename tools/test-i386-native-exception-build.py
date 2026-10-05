#!/usr/bin/env python3
"""Compile the actual exception-entry module using the resident guest compiler."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--reference', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    dependencies = [Path(__file__), args.disk, args.reference,
                    ROOT/'tools/i386-kernel-input.py', ROOT/'tools/build-i386-kernel.py',
                    ROOT/'tools/test-i386-retained-build.py']
    pins = {str(p.resolve()): digest(p) for p in dependencies}
    report = {'result': 'fail', 'input_sha256': pins,
              'scope': 'Actual native ExceptionEntry compilation and export contract; not full generation or byte equivalence'}
    try:
        disk = out/'candidate.img'
        shutil.copyfile(args.disk, disk)
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(disk, out/'build', snapshot=False, ram_mib=8,
            accel='kvm', startup_check={'status': 'ok', 'answers': [],
                'command_timeout': 600, 'commands': [
                    ('I386BuildModule("C:/Kernel/I386/ExceptionEntry.HC","C:/Probe/NativeException.t32m",TRUE)>0;', ['1'])]})
        files = runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents']
        module = files(disk, {'/Probe/NativeException.t32m'})['/Probe/NativeException.t32m']
        (out/'ExceptionEntry.t32m').write_bytes(module)
        layout = runpy.run_path(str(ROOT/'tools/test-i386-retained-build.py'))['exports_of']
        records, exports = layout(module)
        _, expected = layout(args.reference.read_bytes())
        if set(exports) != set(expected):
            raise ValueError('Native exception exports differ from cross-built contract')
        if any(digest(Path(p)) != h for p, h in pins.items()):
            raise ValueError('Qualification inputs changed')
        report.update(result='pass', records=records, exports=exports,
                      module_sha256=hashlib.sha256(module).hexdigest())
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
