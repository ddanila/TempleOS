#!/usr/bin/env python3
"""Exercise actual boot-publication core with a bounded fake ATA transport in HolyC."""
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
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    overlay = out / 'overlay'
    overlay.mkdir(parents=True)
    core = ROOT / 'Kernel/I386/InstallBootArea.HC'
    fixture = ROOT / 'tests/guest/i386-install-area/Contract.HC'
    source = core.read_text()
    boundary = '//Mounted-drive entry point.'
    if source.count(boundary) != 1:
        raise ValueError('Cannot isolate actual boot-area transport core')
    inputs = (core, fixture, Path(__file__), ROOT / 'Kernel/I386/Ata.HH',
              ROOT / 'tools/build-iso.py', ROOT / 'tools/guest-run.py',
              ROOT / 'build/rebuild-test/overlay/Compiler/Compiler.BIN',
              ROOT / 'build/rebuild-test/overlay/0000Boot/0000Kernel.BIN.C')
    pins = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
    (overlay / 'BootAreaCore.HC').write_text(source.split(boundary)[0])
    (overlay / 'Once.HC').write_bytes(fixture.read_bytes())
    report = {'result': 'running', 'input_sha256': pins,
              'scope': 'Actual HolyC publication core, fake ATA; 16/32/64 MiB, blank/alias/bounds guards, interrupted writes/flush and boot-sector-last; not real ATA qualification'}
    try:
        subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', str(ROOT / 'build/rebuild-test/overlay'),
                        '--overlay', str(overlay), '--output', str(out / 'test.iso')], cwd=ROOT, check=True)
        subprocess.run([sys.executable, 'tools/guest-run.py', str(out / 'test.iso'), '--out', str(out / 'guest'),
                        '--qmp-stdio', '--timeout', '120'], cwd=ROOT, check=True)
        if 'DONE install-area 20 cases\n' not in (out / 'guest/debug.log').read_text():
            raise ValueError('Missing publication contract result')
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
