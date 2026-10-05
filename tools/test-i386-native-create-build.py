#!/usr/bin/env python3
"""Compile RedSeaCreate from guest source and verify exact module/poll records."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', type=Path, required=True)
    parser.add_argument('--disk', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists():
        parser.error('Use a fresh output directory')
    args.out.mkdir(parents=True)
    helper = args.repository.resolve()/'tools/build-i386-kernel.py'
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    inputs = [Path(__file__).resolve(), args.disk.resolve(), helper, ROOT/'tools/i386-kernel-input.py']
    pins = {str(p): sha(p) for p in inputs}
    report = {'result': 'fail', 'input_sha256': pins}
    disk = args.out/'candidate.img'
    shutil.copyfile(args.disk, disk)
    try:
        report['behavior'] = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
            disk, args.out/'build', snapshot=False, ram_mib=8, accel='kvm',
            startup_check={'status': 'ok', 'answers': [], 'command_timeout': 300,
                          'commands': [('I386BuildModule("C:/Kernel/I386/RedSeaCreate.HC","C:/Probe/SourceCreate.t32m")>0;', ['1'])]})
        build = runpy.run_path(str(helper))
        module = build['mutated_file_contents'](disk, {'/Probe/SourceCreate.t32m'})['/Probe/SourceCreate.t32m']
        (args.out/'SourceCreate.t32m').write_bytes(module)
        report['module'] = build['verify_native_create_module'](
            disk, '/Probe/SourceCreate.t32m', '/Probe/SourceCreate.bin')
        if any(sha(Path(p)) != h for p, h in pins.items()):
            raise ValueError('Native creator qualification inputs changed')
        report.update(result='pass', inputs_unchanged=True)
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')


if __name__ == '__main__':
    main()
