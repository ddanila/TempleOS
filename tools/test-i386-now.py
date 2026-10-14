#!/usr/bin/env python3
"""Check the public RTC date binding, monotonic reads and timezone offset."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [('CDate ClockFirst=Now;', []),
            ('CDateStruct ClockParts;', []),
            ('Date2Struct(&ClockParts,ClockFirst);', []),
            ('ClockParts.year>=2020&&ClockParts.year<2100&&ClockParts.mon>=1&&ClockParts.mon<=12&&ClockParts.day_of_mon>=1&&ClockParts.day_of_mon<=31;', ['1']),
            ('CDate ClockSecond=Now;ClockSecond>=ClockFirst;', ['1']),
            ('CDate ClockOldOffset=local_time_offset;local_time_offset=0x10000000;', ['268435456']),
            ('CDate ClockShifted=Now;ClockShifted+0x10000000>=ClockSecond&&ClockShifted+0x10000000-ClockSecond<0x1000000;', ['1']),
            ('local_time_offset=ClockOldOffset;', ['0']), ('6*7;', ['42'])]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Public Now date fields, monotonicity and caller-controlled offset; not RTC hardware-mode or precise wall-clock qualification',
                  input_sha256=pins, commands=commands)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=64,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'rejection_prefixes':('INPUT REJECT ',),
                           'command_timeout':120})
        report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Native fixture inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':
        raise ValueError(report['error'])


if __name__=='__main__':
    main()
