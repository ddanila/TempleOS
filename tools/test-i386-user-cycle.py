#!/usr/bin/env python3
"""Diagnose a User create/kill cycle inside one running HolyC call."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys
import threading
import time

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
    parser.add_argument('disk', type=Path, nargs='?')
    parser.add_argument('--original', action='store_true')
    parser.add_argument('--async-stop', action='store_true')
    parser.add_argument('--command-timeout', type=float, default=120)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if args.original == (args.disk is not None):
        parser.error('Specify either --original or an i386 disk')
    if args.command_timeout <= 0:
        parser.error('Command timeout must be positive')
    args.out.mkdir(parents=True, exist_ok=True)
    sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
    checker, base, disk = sha(Path(__file__)), sha(BASE), sha(args.disk) if args.disk else None
    report = {'result': 'fail', 'checker_sha256': checker, 'base_sha256': base,
              'disk_sha256': disk, 'async_stop': args.async_stop, 'command_timeout': args.command_timeout, 'scope': 'One empty User create/kill cycle inside one HolyC call, with phase markers; not resource recovery'}
    timings = []
    stop = threading.Event()
    started = time.monotonic()
    log_path = args.out/('original/debug.log' if args.original else 'behavior/debug.log')
    def observe():
        seen = 0
        while not stop.wait(.05):
            if log_path.exists():
                phases = [line for line in log_path.read_text().splitlines()
                          if line.startswith(('USER CYCLE ', 'USER headers ', 'USER input '))]
                for phase in phases[seen:]:
                    timings.append({'phase': phase, 'seconds_since_start': time.monotonic()-started})
                seen = len(phases)
    watcher = threading.Thread(target=observe, daemon=True)
    watcher.start()
    try:
        definitions = list(DEFINITIONS)
        if args.async_stop:
            definitions.insert(-2, 'U0 UserCycleState(){U8 s[128];StrPrint(s,"USER CYCLE state %X %d %d\\n",GetRFlags,cnts.jiffies,UserProbeHas);UserCycleLog(s);}')
            definitions[-2] = 'Bool UserCycleStop(){UserCycleLog("USER CYCLE stop\\n");Bool ok=Kill(UserProbeTask,FALSE);UserCycleState;I64 i;for(i=0;i<20&&UserProbeHas;i++)Yield;UserCycleState;WinFocus(Fs);if(!UserProbeHas)UserCycleLog("USER CYCLE retired\\n");return ok&&!UserProbeHas;}'
        commands = [(s, []) for s in definitions] + [('UserOneCycle;', ['1']), ('6*7;', ['42'])]
        if any(len(s) > 255 for s, _ in commands):
            raise ValueError('Cycle fixture exceeds interactive line limit')
        if args.original:
            overlay = args.out/'overlay'
            overlay.mkdir(exist_ok=True)
            source = '\n'.join(definitions)+'\nBool ok=UserOneCycle;\n'
            source += 'if(ok)UserCycleLog("PASS original User cycle\\n");else UserCycleLog("FAIL original User cycle\\n");UserCycleLog("DONE original User cycle\\n");\n'
            (overlay/'Once.HC').write_text(source)
            iso = args.out/'original.iso'
            subprocess.run([sys.executable, 'tools/build-iso.py', '--overlay', 'build/rebuild-test/overlay', '--overlay', str(overlay), '--output', str(iso)], cwd=ROOT, check=True)
            subprocess.run([sys.executable, 'tools/guest-run.py', str(iso), '--out', str(args.out/'original'), '--timeout', '90'], cwd=ROOT, check=True)
            if 'PASS original User cycle\n' not in (args.out/'original/debug.log').read_text():
                raise ValueError('Missing original cycle verdict')
        else:
            runner = runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
            report['behavior'] = runner(args.disk, args.out/'behavior', cpu='486,-fpu',
                qmp_stdio=True, startup_check={'status':'ok', 'answers':[], 'commands':commands, 'command_timeout':args.command_timeout})
        report['result'] = 'pass'
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        stop.set()
        watcher.join()
        report['phase_timings'] = timings
        log = args.out/('original/debug.log' if args.original else 'behavior/debug.log')
        report['phases'] = [s for s in log.read_text().splitlines() if s.startswith('USER CYCLE ')] if log.exists() else []
        report['source_disk_unchanged'] = args.disk is None or sha(args.disk) == disk
        if not report['source_disk_unchanged'] or sha(Path(__file__)) != checker or sha(BASE) != base:
            report.update(result='fail', error='Disk or checker changed during execution')
        (args.out/'result.json').write_text(json.dumps(report, indent=2)+'\n')
    if report['result'] != 'pass':
        raise SystemExit(1)


if __name__ == '__main__':
    main()
