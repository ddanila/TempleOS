#!/usr/bin/env python3
"""Compare bounded module serialization with the actual contiguous HolyC packer."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument("--writer-core", type=Path, help="Alternate core for controlled mutation/red tests")
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    overlay = out / 'overlay'
    overlay.mkdir(parents=True)
    core = args.writer_core.resolve() if args.writer_core else ROOT / 'Kernel/I386/ModuleWriteCore.HC'
    fixture = ROOT / 'tests/guest/i386-module-writer/Contract.HC'
    inputs = (core, fixture, Path(__file__), ROOT / 'Kernel/I386/Module.HH', ROOT / 'Kernel/I386/ModuleCheck.HH',
              ROOT / 'Kernel/I386/ModuleCheck.HC', ROOT / 'Kernel/I386/ModulePackCore.HC',
              ROOT / 'tools/build-iso.py', ROOT / 'tools/guest-run.py',
              ROOT / 'build/rebuild-test/overlay/Compiler/Compiler.BIN',
              ROOT / 'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C')
    pins = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
    core_target = overlay / 'Kernel/I386/ModuleWriteCore.HC'
    core_target.parent.mkdir(parents=True)
    core_target.write_bytes(core.read_bytes())
    (overlay / 'Once.HC').write_bytes(fixture.read_bytes())
    report = {'result': 'running', 'input_sha256': pins,
              'scope': 'Actual HolyC bounded writer vs contiguous byte oracle, 6 scratch sizes, 30 short/error sinks, 11 invalid requests and 10 borrowed-span checks; host-compiled core only, not native frontend/staging integration'}
    try:
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', str(ROOT / 'build/rebuild-test/overlay'),
                        '--overlay', str(overlay), '--output', str(out / 'test.iso')], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(out / 'test.iso'), '--out', str(out / 'guest'),
                        '--qmp-stdio', '--timeout', '120'], cwd=ROOT, check=True)
        if 'DONE module-writer 6 identical 30 write-failures 11 invalid 10 span-checks\n' not in (out / 'guest/debug.log').read_text():
            raise ValueError('Missing writer contract result')
        if any(hashlib.sha256(Path(p).read_bytes()).hexdigest() != h for p, h in pins.items()):
            raise ValueError('Test inputs changed')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
