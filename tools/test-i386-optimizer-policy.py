#!/usr/bin/env python3
"""Exercise shared optimizer branch policies on the classic compiler host."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--out', type=Path, required=True)
    args = ap.parse_args()
    out = args.out.resolve()
    if out.exists():
        ap.error('Use a fresh output directory')
    fixture = ROOT/'tests/guest/i386-optimizer-policy/Once.HC'
    inputs = set()

    def collect(path):
        if path in inputs:
            return
        inputs.add(path)
        for name in re.findall(rb'^#include "([^"]+)"', path.read_bytes(), re.M):
            collect(ROOT/name.decode('ascii').lstrip('/'))

    collect(fixture)
    bootstrap = ROOT/'build/rebuild-test/overlay'
    inputs.update([Path(__file__).resolve(), ROOT/'tools/build-iso.py',
                   ROOT/'tools/guest-run.py', bootstrap/'Compiler/Compiler.BIN',
                   bootstrap/'0000Boot/0000Kernel.BIN.C'])
    pins = {str(p): sha(p) for p in sorted(inputs)}
    out.mkdir()
    report = dict(result='running', input_sha256=pins,
                  scope='Classic host execution of the complete shared optimizer core: invocation-local zero/nonzero callbacks and unchanged default wrapper, three passes per graph, i386-flag bypass, exact counters and zero caller heap delta. Instrumented policies do not qualify actual branch rewrites or public use of the resident native core.')
    try:
        overlay = out/'overlay'
        overlay.mkdir()
        (overlay/'Once.HC').write_bytes(fixture.read_bytes())
        image = out/'compiler.iso'
        subprocess.run(['python3', 'tools/build-iso.py', '--overlay', str(bootstrap),
                        '--overlay', str(overlay), '--output', str(image)], cwd=ROOT, check=True)
        report['image_sha256'] = sha(image)
        subprocess.run(['python3', 'tools/guest-run.py', str(image), '--out',
                        str(out/'guest'), '--qmp-stdio', '--timeout', '60'], cwd=ROOT, check=True)
        report['trace'] = list(struct.unpack('<17q', (out/'guest/optimizer-policy.bin').read_bytes()))
        if report['trace'] != [3, 0, 3, 0, 0, 3, 0, 3]+[0]*9:
            raise ValueError('Policy dispatch or heap counters differ')
        assert (out/'guest/debug.log').read_text().count('DONE optimizer policy dispatch\n') == 1
        assert sha(image) == report['image_sha256']
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == h for p, h in pins.items())
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
        assert report['inputs_unchanged']


if __name__ == '__main__':
    main()
