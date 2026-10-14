#!/usr/bin/env python3
"""Require a large public allocation with touched pages, intact edges and release."""
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
    parser.add_argument('--out', required=True, type=Path)
    parser.add_argument('--ram-mib', choices=(64, 128), type=int, default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    # Separate commands retain the allocation across prompt compilations.
    # Touch every 4 KiB and both endpoints, then read back before release.
    size = (32 if args.ram_mib == 64 else 80)*1024*1024
    commands = [(f'U8 *CapacityBlock=MAlloc({size});', []),
                (f'I64 CapacityTouch(){{I64 i;for(i=0;i<{size};i+=4096)CapacityBlock[i]=(i/4096)%251;CapacityBlock[{size-1}]=173;return 1;}}', []),
                ('CapacityTouch;', ['1']),
                (f'I64 CapacityVerify(){{I64 i;for(i=0;i<{size};i+=4096)if(CapacityBlock[i]!=(i/4096)%251)return 0;return CapacityBlock[{size-1}]==173;}}', []),
                ('CapacityVerify;', ['1']), ('Free(CapacityBlock);', []),
                ('6*7;', ['42'])]
    report = dict(result='running', ram_mib=args.ram_mib, requested_bytes=size,
                  scope='Public allocation capacity with page/endpoint readback and normal release; not full memory-map qualification',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejected_answers':['Out of memory'], 'command_timeout':120})
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Test input changed')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
