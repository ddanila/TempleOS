#!/usr/bin/env python3
"""Exercise parser scratch on a preserved installed image at 8 MiB."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [('6*7;', ['42'])] * 3 + [
    ('I64 ScratchNested(I64 a){return (a+1)*(a-1)+7;}', []),
    ('ScratchNested(6);', ['42']),
    ('I64 ScratchRecursive(I64 a){if(a<2)return 1;return a*ScratchRecursive(a-1);}', []),
    ('ScratchRecursive(5);', ['120']),
    ('DocAllocationCheck;', ['13']),
] + [('6*7;', ['42'])] * 3


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    disk, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p): sha(p) for p in (disk, runner, Path(__file__).resolve())}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(disk, working)
    report = dict(result='running', ram_mib=8, cpu='486,-fpu',
                  scope='Installed-image parser scratch, repeated expressions, nested/recursive functions and DolDoc allocation; not exhaustive ownership or OS acceptance',
                  input_sha256=pins, commands=COMMANDS)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=8,
            accel='tcg', cpu='486,-fpu', qmp_stdio=True,
            startup_timeout=180,
            startup_check={'status':'ok', 'answers':[], 'commands':COMMANDS})
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['input_unchanged'] = all(sha(Path(p)) == digest for p, digest in pins.items())
        if not report['input_unchanged']:
            report.update(result='fail', error='Preserved input changed during test')
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if not report['input_unchanged']:
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
