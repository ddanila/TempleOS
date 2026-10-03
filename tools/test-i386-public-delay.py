#!/usr/bin/env python3
"""Exercise original public Yield/Sleep/SleepUntil semantics in the native guest."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy

ROOT = Path(__file__).resolve().parents[1]
PUBLIC = runpy.run_path(str(ROOT / 'tools/test-i386-required-services.py'))
DELAYS = ('Yield', 'Sleep', 'SleepUntil')


def delay_presence(log):
    values = {}
    for name in PUBLIC['CONTROLS'] + DELAYS:
        found = re.findall(r'^M7 SERVICE ' + name + r' ([01])$', log, re.M)
        if len(found) != 1:
            return {'result': 'invalid', 'reason': f'Missing or repeated observation: {name}'}
        values[name] = int(found[0])
    if any(values[name] != 1 for name in PUBLIC['CONTROLS']):
        return {'result': 'invalid', 'reason': 'Public lookup controls failed'}
    missing = [name for name in DELAYS if not values[name]]
    return {'result': 'fail' if missing else 'pass', 'missing': missing, 'functions': values}


def behavior_commands():
    return [
        ('I64 DelayIdentity(){CTask *me=Fs;I64 f=GetRFlags;Yield;Sleep(0);return Fs==me&&(GetRFlags&512)==(f&512);}', []),
        ('DelayIdentity;', ['1']),
        ('I64 DelayDeadline(){I64 t=cnts.jiffies;Sleep(20);return cnts.jiffies-t>=20&&!Bt(&Fs->task_flags,TASKf_IDLE);}', []),
        ('DelayDeadline;', ['1']),
        ('I64 DelayIdle(){I64 f=Fs->task_flags;Fs->task_flags|=1<<TASKf_IDLE;SleepUntil(cnts.jiffies+10);I64 ok=Bt(&Fs->task_flags,TASKf_IDLE);Fs->task_flags=f;return ok;}', []),
        ('DelayIdle;', ['1']),
        ('I64 DelayPast(){I64 f=GetRFlags;SleepUntil(cnts.jiffies-1);Sleep(-1);return !Bt(&Fs->task_flags,TASKf_IDLE)&&(GetRFlags&512)==(f&512);}', []),
        ('DelayPast;', ['1']),
        ('I64 DelayMasked(){I64 f=GetRFlags;SetRFlags(f&~512);Yield;Sleep(10);I64 ok=!(GetRFlags&512);SetRFlags(f);return ok;}', []),
        ('DelayMasked;', ['1']),
        ('6*7;', ['42']),
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / 'result.json').unlink(missing_ok=True)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    disk_hash = sha(args.disk)
    runner = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    presence = runner(args.disk, out / 'presence', cpu='486,-fpu', qmp_stdio=True,
                      startup_check={'status': 'ok', 'answers': [], 'commands':
                                     PUBLIC['observation_commands'](PUBLIC['CONTROLS'] + DELAYS)})
    report = delay_presence((out / 'presence/debug.log').read_text())
    report.update(cpu='486,-fpu', ram_mib=8, accel='tcg', disk_sha256=disk_hash,
                  presence_console=presence, checker_sha256=sha(Path(__file__)),
                  publication_checker_sha256=sha(ROOT / 'tools/test-i386-required-services.py'),
                  scope='Public cooperative delay behavior; not Spawn/Exit or multiple terminals')
    if report['result'] == 'pass':
        report['behavior'] = runner(args.disk, out / 'behavior', cpu='486,-fpu', qmp_stdio=True,
                                    startup_check={'status': 'ok', 'answers': [], 'commands': behavior_commands()})
    if sha(args.disk) != disk_hash:
        raise ValueError('Delay test changed source disk')
    report['source_disk_unchanged'] = True
    (out / 'result.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if report['result'] == 'pass' else 1 if report['result'] == 'fail' else 2)


if __name__ == '__main__':
    main()
