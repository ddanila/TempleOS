#!/usr/bin/env python3
"""Exercise original logical mouse state with native PS/2 hardware events."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT/'tests/guest/i386-mouse-state/MouseState.HC'
COMMANDS = [
    ('#include "/Kernel/I386/PublicUser.HH"', []),
    ('#include "C:/MouseState.HC"', []),
    ('MSTProbe;', ['63'], {
        'begin':'MS TEST ready\n','initial_rows':['A'],
        'events':[
            {'mouse_to':[350,250]}, {'wait_log':'MS TEST motion\n'},
            {'mouse_button':'left','down':True}, {'wait_log':'MS TEST left\n'},
            {'mouse_button':'right','down':True}, {'wait_log':'MS TEST right\n'},
            {'key':'a'}, {'wait_log':'MS TEST keyboard\n'},
            {'mouse_button':'left','down':False}, {'mouse_button':'right','down':False},
            {'wait_log':'MS TEST snap ready\n'},
            {'mouse_to':[358,262]}, {'wait_log':'MS TEST snap\n'}],
        'final_rows':['A'], 'preserve_history':True,
        'exit_key':'esc','end':'MS TEST end\n'}),
    ('6*7;', ['42']),
]


def serializable(value):
    if isinstance(value,dict):
        return {str(key):serializable(item) for key,item in value.items()}
    if isinstance(value,(list,tuple)):
        return [serializable(item) for item in value]
    if isinstance(value,set):
        return [serializable(item) for item in sorted(value)]
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, ROOT/'Kernel/FontStd.HC', FIXTURE, ROOT/'tools/package-i386-native-image.py', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](source, working, additions={'/MouseState.HC': FIXTURE.read_bytes()})
    report = dict(result='running', scope='PS/2 motion, both buttons, text coordinates, timestamp, speed, scaling and grid snapping; not complete original mouse qualification',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True, welcome=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':False,
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
