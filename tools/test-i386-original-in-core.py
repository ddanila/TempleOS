#!/usr/bin/env python3
"""Compile and check current shared In directly in original TempleOS."""
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
    parser.add_argument('--failure', action='store_true')
    args = parser.parse_args()
    if args.out.exists(): parser.error('Use a fresh output directory')
    out = args.out.resolve(); overlay = out/'overlay'; overlay.mkdir(parents=True)
    core = ROOT/'Kernel/JobInCore.HC'
    fixture = ROOT/'tests/guest/i386-in-text'/('Failure.HC' if args.failure else 'Contract.HC')
    files = [Path(__file__).resolve(), core, fixture, ROOT/'tools/build-iso.py', ROOT/'tools/guest-run.py']
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in files}
    report = dict(result='running', input_sha256=pins, failure=args.failure,
                  scope='Current shared In body compiled as ITOracleIn in original TempleOS; intercepted InStr, not boot-bound In or actual input delivery')
    try:
        source = core.read_text().replace('U0 In(', 'U0 ITOracleIn(', 1)
        source += fixture.read_text().replace('In(', 'ITOracleIn(')
        source += '\nU0 ITReport(U8 *s){while(*s)OutU8(0xE9,*s++);}\n'
        source += 'I64 it_mask=ITContract;U8 *it_line=MStrPrint("OBS current In mask %d\\n",it_mask);ITReport(it_line);Free(it_line);\n'
        source += 'ITReport("DONE current In\\n");\n'
        (overlay/'Once.HC').write_text(source)
        iso = out/'original.iso'
        subprocess.run([sys.executable, str(ROOT/'tools/build-iso.py'), '--overlay', str(ROOT/'build/rebuild-test/overlay'), '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
        subprocess.run([sys.executable, str(ROOT/'tools/guest-run.py'), str(iso), '--out', str(out/'behavior'), '--timeout', '90', '--qmp-stdio'], cwd=ROOT, check=True)
        log = (out/'behavior/debug.log').read_text()
        report['observations'] = [line for line in log.splitlines() if line.startswith('OBS current In')]
        if 'OBS current In mask 63\n' not in log or 'DONE current In\n' not in log:
            raise ValueError('Current shared In contract did not pass')
        report['result'] = 'pass'
    except Exception as error:
        report.update(result='fail', error=str(error)); raise
    finally:
        changed = [p for p,h in pins.items() if sha(Path(p)) != h]
        if changed: report.update(result='fail', changed_inputs=changed)
        (out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass': raise RuntimeError('In oracle inputs changed')

if __name__ == '__main__': main()
