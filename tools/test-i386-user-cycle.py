#!/usr/bin/env python3
"""Diagnose a User create/kill cycle inside one running HolyC call."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT/'tools/test-i386-user-create.py'
DEFINITIONS = runpy.run_path(str(BASE))['DEFINITIONS'] + [
    'U0 UserCycleLog(U8 *s){while(*s)OutU8(0xE9,*s++);}',
    'Bool UserCycleStart(){UserCycleLog("USER CYCLE start\\n");Bool ok=UserProbeStart(FALSE);UserCycleLog("USER CYCLE created\\n");return ok;}',
    'Bool UserCycleStop(){UserCycleLog("USER CYCLE stop\\n");Bool ok=UserProbeStop;UserCycleLog("USER CYCLE retired\\n");return ok;}',
    'Bool UserOneCycle(){return UserCycleStart&&UserCycleStop;}',
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    checker, base, disk = sha(Path(__file__)), sha(BASE), sha(args.disk)
    report = {'result': 'fail', 'checker_sha256': checker, 'base_sha256': base,
              'disk_sha256': disk, 'scope': 'One empty User create/kill cycle inside one HolyC call, with phase markers; not resource recovery'}
    try:
        commands = [(s, []) for s in DEFINITIONS] + [('UserOneCycle;', ['1']), ('6*7;', ['42'])]
        if any(len(s) > 255 for s, _ in commands):
            raise ValueError('Cycle fixture exceeds interactive line limit')
        runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior'] = runner(args.disk, args.out/'behavior', cpu='486,-fpu',
            qmp_stdio=True, startup_check={'status':'ok', 'answers':[], 'commands':commands, 'command_timeout':120})
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        log = args.out/'behavior/debug.log'
        report['phases'] = [s for s in log.read_text().splitlines() if s.startswith('USER CYCLE ')] if log.exists() else []
        report['source_disk_unchanged'] = sha(args.disk) == disk
        if not report['source_disk_unchanged'] or sha(Path(__file__)) != checker or sha(BASE) != base:
            report.update(result='fail', error='Disk or checker changed during execution')
        (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise SystemExit(1)


if __name__ == '__main__':
    main()
