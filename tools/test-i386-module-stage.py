#!/usr/bin/env python3
"""Exercise the actual HolyC module staging lifecycle with injected transport faults."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument("--stage-core", type=Path, help="Alternate core for controlled mutation/red tests")
    parser.add_argument('--validation', action='store_true', help='Exercise staged validation without a whole code buffer')
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    overlay = out / 'overlay'
    overlay.mkdir(parents=True)
    core_name = 'ModuleStageCheck.HC' if args.validation else 'ModuleStageCore.HC'
    core = args.stage_core.resolve() if args.stage_core else ROOT / 'Kernel/I386' / core_name
    fixture = ROOT / 'tests/guest/i386-module-stage' / ('Validation.HC' if args.validation else 'Contract.HC')
    inputs = (core, fixture, Path(__file__), ROOT / 'Kernel/I386/ModuleStage.HH',
              ROOT / 'tools/build-iso.py', ROOT / 'tools/guest-run.py',
              ROOT / 'build/rebuild-test/overlay/Compiler/Compiler.BIN',
              ROOT / 'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C')
    if args.validation:
        inputs += tuple(ROOT / name for name in ('Kernel/I386/ModuleCheck.HC',
                        'Kernel/I386/ModuleCheck.HH', 'Kernel/I386/Module.HH',
                        'Kernel/NumericLimits.HH'))
    pins = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
    core_target = overlay / 'Kernel/I386' / core_name
    core_target.parent.mkdir(parents=True)
    core_target.write_bytes(core.read_bytes())
    (core_target.parent / 'ModuleStage.HH').write_bytes((ROOT / 'Kernel/I386/ModuleStage.HH').read_bytes())
    if args.validation:
        for name in ('Kernel/I386/ModuleCheck.HC', 'Kernel/I386/ModuleCheck.HH',
                     'Kernel/I386/Module.HH', 'Kernel/NumericLimits.HH'):
            target = overlay / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes((ROOT / name).read_bytes())
    (overlay / 'Once.HC').write_bytes(fixture.read_bytes())
    report = {'result': 'running', 'input_sha256': pins,
              'scope': 'Actual HolyC staging state machine with short/error/thrown writes, flush/read failures and release retry; host core only, no RedSea reservation or task-kill integration'}
    label, expected = ('stage-validation', '46') if args.validation else ('module-stage', '253')
    if args.validation:
        report['scope'] = 'Actual HolyC staged validator with header bounds, cached relocation reads and read failures; host contract, not publication or native integration'
    try:
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', str(ROOT / 'build/rebuild-test/overlay'),
                        '--overlay', str(overlay), '--output', str(out / 'test.iso')], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(out / 'test.iso'), '--out', str(out / 'guest'),
                        '--qmp-stdio', '--timeout', '120'], cwd=ROOT, check=True)
        log = (out / 'guest/debug.log').read_text()
        done = re.findall(r'^DONE ' + label + r' (\d+) checks$', log, re.MULTILINE)
        if done != [expected] or re.search(r'^FAIL ' + label + r'\b', log, re.MULTILINE):
            raise ValueError('Missing complete stage contract result')
        report['checks'] = int(done[0])
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
