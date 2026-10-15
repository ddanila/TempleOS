#!/usr/bin/env python3
"""Require original class form metadata and interactions."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
FIXTURE=ROOT/"tests/guest/i386-class-form-reference/Form.HC"
COMMANDS = [('class FPCMeta {I64 value;}; U8*FPTypeProbe(U8*p,U8*name=lastclass){return name;}',[]),
            ('FPCMeta fp_meta;!StrCmp(FPTypeProbe(&fp_meta),"FPCMeta");',['1']),('Bool FPGate(U8*p){return DocForm(p,"FPNumeric");}',[]),
            ('#include "C:/Form.HC"',[])]+[(f'FPCheck({i});',['63']) for i in range(7)]+[('6*7;',['42'])]

if any(len(c[0])>255 for c in COMMANDS):
    raise ValueError("Class form fixture exceeds native input limit")


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
    parser.add_argument('--observe',action='store_true',
                        help='Record masks without asserting compatibility; diagnostic evidence only')
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if args.observe:
        commands = commands[:4]+[
            ('U0 FPProbe(I64 i){I64 m=FPContract(i);U8*s=MStrPrint("FORM PROBE %d %d %d %d %d %d %d\\n",i,m,fp_bound[i],fp_seen_each[i],fp_heap_delta[i],fp_numeric_value[i],fp_typed[i]),*p=s;while(*p)OutU8(0xE9,*p++);Free(s);}', [])
        ]+[(f'FPProbe({i});',[]) for i in range(7)]+[('6*7;',['42'])]
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, FIXTURE, ROOT/'Kernel/FontStd.HC', ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    packaging = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
        source, working, additions={'/Form.HC':FIXTURE.read_bytes()})
    report = dict(result='running', scope='Class form bindings, explicit/inferred names, accept/cancel, real numeric input, guards, task sizing/restoration and exact caller heap; shared root deltas are telemetry',
                  packaging=packaging, input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
            startup_check={'status':'ok', 'answers':[], 'commands':commands,
                           'pause_window_manager':False,
                           'rejected_answers':['0'],
                           'rejection_prefixes':('INPUT REJECT ','WINMGR window exception '),
                           'command_timeout':120})
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        saved=build['mutated_file_contents'](working,{'/Form.HC'}).get('/Form.HC')
        if saved!=FIXTURE.read_bytes():raise ValueError('Guest class form fixture differs from source')
        report['guest_fixture_sha256']=sha(FIXTURE)
        if args.observe:
            log=(out/'qemu/debug.log').read_text()
            report['observations']=[list(map(int,line.split()[2:])) for line in log.splitlines() if line.startswith('FORM PROBE ')]
            if [row[0] for row in report['observations']] != list(range(7)):
                raise ValueError('Missing form observations')
            report['observation_columns']=['case','mask','binding_mask','key_observations','caller_heap_delta','numeric_value','typed_tag_is_42']
            report.update(result='observed', qualification='diagnostic-only; no compatibility acceptance')
        else:
            report['result'] = 'pass'
    except Exception as exc:
        report.update(result='fail', error=str(exc))
        raise
    finally:
        log_path=out/'qemu/debug.log'
        if log_path.exists():
            report['failed_contracts']=[list(map(int,line.split()[2:])) for line in log_path.read_text().splitlines() if line.startswith('FORM FAILURE ')]
        report['inputs_unchanged'] = all(sha(Path(p)) == digest for p,digest in pins.items())
        if not report['inputs_unchanged']:
            report.update(result='fail', error='Native fixture inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result'] not in ('pass','observed'):
        raise ValueError(report['error'])


if __name__=='__main__':
    main()
