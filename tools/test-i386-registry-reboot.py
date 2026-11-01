#!/usr/bin/env python3
"""Check that a native registry branch survives a cold reboot."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / 'tools/i386-kernel-input.py'
BOOTS = [
    [('#include "/Kernel/I386/PublicUser.HH"', []),
     ('I64 CRValue;', []),
     ('I64 CRCreate(){return !RegDft("Q/R","CRValue=42;\\n");}', []),
     ('CRCreate;', ['1'])],
    [('#include "/Kernel/I386/PublicUser.HH"', []),
     ('I64 CRValue;', []),
     ('I64 CRCheck(){Bool s=Silent(1);RegExe("Q/R");Silent(s);return CRValue;}', []),
     ('CRCheck;', ['42'])],
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    if out.exists():
        parser.error('Use a fresh output directory')
    paths = [source, RUNNER, Path(__file__).resolve()]
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    pins = {str(p): sha(p) for p in paths}
    out.mkdir(parents=True)
    working = out / 'working.img'
    shutil.copyfile(source, working)
    report = {'result': 'running', 'scope': 'Native registry branch after cold reboot', 'input_sha256': pins}
    try:
        run_input = runpy.run_path(str(RUNNER))['run_input']
        report['boots'] = []
        for index, commands in enumerate(BOOTS):
            report['boots'].append(run_input(
                working, out / f'boot-{index + 1}', snapshot=False, ram_mib=64,
                cpu='486,-fpu', accel='tcg', qmp_stdio=True, welcome=True,
                startup_check={'status': 'ok', 'answers': [], 'commands': commands,
                               'pause_window_manager': False, 'rejected_answers': ['0'],
                               'rejection_prefixes': ('INPUT REJECT ', 'WINMGR window exception '),
                               'command_timeout': 120}))
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p, digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Inputs changed')
        (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    if report['result'] != 'pass':
        raise ValueError(report['error'])


if __name__ == '__main__':
    main()
