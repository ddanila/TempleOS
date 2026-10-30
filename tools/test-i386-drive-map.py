#!/usr/bin/env python3
"""Require original drive mapping contracts."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
FIXTURE=ROOT/"tests/guest/i386-drive-map-reference/Contract.HC"
COMMANDS = [("Bool DMGate(CDrv*d){return DrvMap('X',d);}",[]),
            ('#include "C:/Native.HC"',[]),('DMIdentity;',['1']),("DMSetup('C');",['1'])]+[(f'DMCheck({i});',['31']) for i in range(15)]+[('6*7;',['42'])]


if any(len(c[0])>255 for c in COMMANDS):
    raise ValueError("drive mapping fixture exceeds native input limit")


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
    parser.add_argument('--root-growth',action='store_true',help='Also force mapped RedSea root relocation and verify all 80 files')
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    growth=FIXTURE.with_name('Growth.HC')
    if args.root_growth:
        commands[-1:-1]=[('#include "C:/Growth.HC"',[]),('DMRootGrowth;',['1'])]
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, FIXTURE, FIXTURE.with_name('Native.HC'), ROOT/'Kernel/FontStd.HC', ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py', Path(__file__).resolve()]}
    if args.root_growth:pins[str(growth)]=sha(growth)
    additions={'/Contract.HC':FIXTURE.read_bytes(),'/Native.HC':FIXTURE.with_name('Native.HC').read_bytes()}
    if args.root_growth:additions['/Growth.HC']=growth.read_bytes()
    out.mkdir(parents=True)
    working = out/'working.img'
    packaging = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
        source, working, additions=additions)
    report = dict(result='running', scope='Original drive mapping, aliases, external and invalid-signature records, file I/O, current directory and child-task visibility',
                  packaging=packaging, input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib, root_growth=args.root_growth)
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
        delivered=build['mutated_file_contents'](working,{'/Contract.HC','/Native.HC'})
        if delivered.get('/Native.HC')!=FIXTURE.with_name('Native.HC').read_bytes():raise ValueError('Native table adapter differs from source')
        saved=delivered.get('/Contract.HC')
        if saved!=FIXTURE.read_bytes():raise ValueError('Guest drive mapping fixture differs from source')
        expected_files={'/Probe/DriveMap/Seed.TXT':b'seed','/Probe/DriveMap/Write.TXT':b'mapped','/Probe/DriveMap/Sub/Child.TXT':b'child'}
        if args.root_growth:
            expected_files.update({f'/MapRoot{i:03d}.TXT':b'grow' for i in range(80)})
            if build['mutated_file_contents'](working,{'/Growth.HC'}).get('/Growth.HC')!=growth.read_bytes():
                raise ValueError('Root growth fixture differs from source')
        persisted=build['mutated_file_contents'](working,set(expected_files))
        if persisted!=expected_files:raise ValueError('Mapped I/O did not persist exact files on the backing volume')
        report['persisted_files_sha256']={name:hashlib.sha256(data).hexdigest() for name,data in expected_files.items()}
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
