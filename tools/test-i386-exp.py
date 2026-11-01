#!/usr/bin/env python3
"""Compare native Exp with original x87 and independent binary64 math."""
import argparse
import hashlib
import json
import math
import struct
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
FIXTURE=ROOT/"tests/guest/i386-exp-reference/Exp.HC"
COMMANDS = [('#include "/Kernel/I386/PublicUser.HH"',[]),
            ('#include "C:/Exp.HC"',[]),
            ('U0 EXSave(){U64*v=EXCollect;FileWrite("C:/EXP.BIN",v,2048);Free(v);}',[]),
            ('EXSave;',[]),('6*7;',['42'])]

if any(len(c[0])>255 for c in COMMANDS):
    raise ValueError("Exp fixture exceeds native input limit")


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
    pins = {str(p):sha(p) for p in [source, runner, FIXTURE, ROOT/'Kernel/FontStd.HC', ROOT/'tools/package-i386-native-image.py', ROOT/'tools/build-i386-kernel.py', ROOT/'tests/i386/exp-reference.bin', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    packaging = runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](
        source, working, additions={'/Exp.HC':FIXTURE.read_bytes()})
    report = dict(result='running', scope='256 Exp inputs compared with original x87 and independent host math',
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
        saved=build['mutated_file_contents'](working,{'/Exp.HC'}).get('/Exp.HC')
        if saved!=FIXTURE.read_bytes():raise ValueError('Guest Exp fixture differs from source')
        observed=build['mutated_file_contents'](working,{'/EXP.BIN'}).get('/EXP.BIN')
        if observed is None or len(observed)!=2048:raise ValueError('Missing Exp results')
        values=struct.unpack('<256Q',observed)
        original=struct.unpack('<256Q',(ROOT/'tests/i386/exp-reference.bin').read_bytes())
        input_bytes=bytes(int(h,16) for h in __import__('re').findall(r'\\x([0-9A-F]{2})',FIXTURE.read_text()))
        inputs=struct.unpack('<256Q',input_bytes)
        deviations=[]; numerical=[]
        for i,(raw,got,ref) in enumerate(zip(inputs,values,original)):
            x=struct.unpack('<d',struct.pack('<Q',raw))[0]
            if math.isnan(x):
                if got&0x7ff8000000000000 != 0x7ff8000000000000:raise ValueError('NaN mismatch')
            elif math.isinf(x):
                if got!=ref:raise ValueError(f'Infinity mismatch {i}: {got:x} != {ref:x}')
            else:
                difference=abs(got-ref);deviations.append(difference)
                if difference>2:raise ValueError(f'Original difference exceeds 2 ulps at {i}: {difference}')
                if -744.0<x<709.782712893384:
                    expected=struct.unpack('<Q',struct.pack('<d',math.exp(x)))[0]
                    distance=abs(got-expected);numerical.append(distance)
                    if distance>1024:raise ValueError(f'Host difference exceeds 1024 ulps at {i}: {distance}')
        report['max_original_ulp_difference']=max(deviations)
        report['max_host_ulp_difference']=max(numerical)
        report['native_exp_sha256']=hashlib.sha256(observed).hexdigest()
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
