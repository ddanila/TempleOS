#!/usr/bin/env python3
"""Compare a random-number family with the original."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
FIXTURE=ROOT/"tests/guest/i386-rand-family-reference/RandFamily.HC"
COMMANDS = [('#include "/Kernel/I386/PublicUser.HH"',[]),
            ('U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}',[]),
            ('#include "C:/RandFamily.HC"',[]),('RFCheck;',['1']),('6*7;',['42'])]

if any(len(c[0])>255 for c in COMMANDS):
    raise ValueError("Random family fixture exceeds native input limit")


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
    parser.add_argument('--reference',type=Path,required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    reference=args.reference.resolve(); manifest=json.loads((reference/'result.json').read_text())
    if manifest.get('result')!='pass' or not manifest.get('inputs_unchanged'):
        raise ValueError('Need passing unchanged original reference')
    expected=reference/'guest/rand-family.bin'
    if len(expected.read_bytes())!=64*8 or hashlib.sha256(expected.read_bytes()).hexdigest()!=manifest.get('capture_sha256'):
        raise ValueError('Invalid or changed original random capture')
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, FIXTURE, ROOT/'Kernel/FontStd.HC', ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py', Path(__file__).resolve(), expected, reference/'result.json']}
    out.mkdir(parents=True)
    working = out/'working.img'
    packaging = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
        source, working, additions={'/RandFamily.HC':FIXTURE.read_bytes(),'/RandFamily.bin':expected.read_bytes()})
    report = dict(result='running', scope='Original seeded random family values and task seed state',
                  packaging=packaging, input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
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
        saved=build['mutated_file_contents'](working,{'/RandFamily.HC'}).get('/RandFamily.HC')
        if saved!=FIXTURE.read_bytes():raise ValueError('Guest random family fixture differs from source')
        report['guest_fixture_sha256']=sha(FIXTURE)
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
