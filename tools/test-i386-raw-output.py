#!/usr/bin/env python3
"""Require original raw output contracts."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct

ROOT = Path(__file__).resolve().parents[1]
FIXTURE=ROOT/"tests/guest/i386-raw-output-reference/Contract.HC"
ORACLE=FIXTURE.with_name("oracle.json")
COMMANDS = [('U0 ROGate(){RawPutChar(65);}',[]),('#include "C:/Contract.HC"',[]),('ROWarm;',[])]+[(f'ROSave({i});',['31']) for i in range(13)]+[('6*7;',['42'])]


if any(len(c[0])>255 for c in COMMANDS):
    raise ValueError("Raw output fixture exceeds native input limit")


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
    pins = {str(p):sha(p) for p in [source, runner, FIXTURE, ORACLE, ROOT/'Kernel/FontStd.HC', ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py', Path(__file__).resolve()]}
    oracle=json.loads(ORACLE.read_text())
    if sha(FIXTURE)!=oracle['fixture_sha256']:raise ValueError('Fixture differs from frozen original oracle')
    out.mkdir(parents=True)
    working = out/'working.img'
    packaging = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
        source, working, additions={'/Contract.HC':FIXTURE.read_bytes()})
    report = dict(result='running', scope='Original raw output state, character controls, cache and hardware planes',
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
        files=build['mutated_file_contents'](working,{'/Contract.HC'}|{f'/RawOutput{i}.BIN' for i in range(13)})
        saved=files.get('/Contract.HC')
        if saved!=FIXTURE.read_bytes():raise ValueError('Guest raw output fixture differs from source')
        report['guest_fixture_sha256']=sha(FIXTURE)
        report['captures']=[]
        for expected in oracle['captures']:
            mode=expected['mode'];data=files.get(f'/RawOutput{mode}.BIN',b'')
            if len(data)!=192048:raise ValueError(f'Raw capture length: {mode}')
            cache=data[48:38448]
            actual=dict(mode=mode,meta=list(struct.unpack_from('<6q',data)),sha256=hashlib.sha256(data).hexdigest(),cache_sha256=hashlib.sha256(cache).hexdigest())
            report['captures'].append(actual)
            if actual!=expected:raise ValueError(f'Raw capture differs from original: {mode}')
            for plane in range(4):
                if data[38448+plane*38400:38448+(plane+1)*38400]!=cache:
                    raise ValueError(f'Raw hardware differs from cache: {mode}, plane {plane}')
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
