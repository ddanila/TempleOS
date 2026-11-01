#!/usr/bin/env python3
"""Require the actual menu chooser contract through public DocMenu."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
FIXTURE=ROOT/"tests/guest/i386-menu-large-page-reference/MenuChooser.HC"
COMMANDS = [('I64 MCPrerequisite(CDoc*d){return DocMenu(d);}',[]),
            ('#include "/Kernel/ScanCodes.HH"',[]),
            ('#include "C:/MenuChooser.HC"',[])]+[(f'MCLarge({i})=={value};',['1'])
            for i,value in enumerate((57,72,1,16,1,57))]+[('6*7;',['42'])]

if any(len(c[0])>255 for c in COMMANDS):
    raise ValueError("Put/display fixture exceeds native input limit")


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
    parser.add_argument('--default-window',action='store_true',help='Compare the unmodified task window to the original')
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    fixture = ROOT/'tests/guest/i386-menu-large-page-default/MenuChooser.HC' if args.default_window else FIXTURE
    commands = list(COMMANDS)
    if args.default_window: commands.insert(3,('MCWindow;',['1']))
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, fixture, ROOT/'Kernel/FontStd.HC', ROOT/'Kernel/ScanCodes.HH', ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    packaging = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
        source, working, additions={'/MenuChooser.HC':fixture.read_bytes()})
    report = dict(result='running', scope='72-entry DocMenu page movement at explicit rows 2-58 and task/document restoration; not arbitrary layouts or mouse input',
                  packaging=packaging, input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    if args.default_window: report['scope']='72-entry DocMenu using task default window compared with original; default geometry remains unqualified'
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True, welcome=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':False,
                           'rejected_answers':['0'],
                           'rejection_prefixes':('INPUT REJECT ','WINMGR window exception '),
                           'command_timeout':120})
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        saved=build['mutated_file_contents'](working,{'/MenuChooser.HC'}).get('/MenuChooser.HC')
        if saved!=fixture.read_bytes():raise ValueError('Guest DocEd fixture differs from source')
        report['guest_fixture_sha256']=sha(fixture)
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
