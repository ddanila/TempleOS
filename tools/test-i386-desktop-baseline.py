#!/usr/bin/env python3
"""Observe existing interactive behavior at the proposed desktop memory profiles."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib', type=int, choices=(64, 128), default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    runner = ROOT/'tools/i386-kernel-input.py'
    commands = runpy.run_path(str(ROOT/'tools/test-i386-startup-memory.py'))['COMMANDS']
    pins = {str(p):sha(p) for p in (source, runner, Path(__file__).resolve())}
    out.mkdir(parents=True)
    disk = out/'working.img'
    shutil.copyfile(source, disk)
    report = dict(result='running', input_sha256=pins, ram_mib=args.ram_mib,
                  scope='Existing nine-command retained-state and VGA baseline at larger RAM; not full original desktop or application compatibility',
                  commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            disk, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands})
        log = (out/'qemu/debug.log').read_text()
        if 'BUILD PROVIDER loaded\n' in log:
            raise ValueError('Normal startup loaded build-only support')
        report.update(result='pass', build_provider_loads=0)
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Input changed during baseline')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])
    print('PASS: existing interactive baseline at', args.ram_mib, 'MiB')


if __name__ == '__main__':
    main()
