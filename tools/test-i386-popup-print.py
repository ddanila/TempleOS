#!/usr/bin/env python3
"""Require formatted popup source execution, wide values and escaped strings."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('I64 PPValue(){return PopUpPrint("%d+%d;",19,23)==42;}', []),
    ('I64 PPWide(){return PopUpPrint("-0x%X;",7)==-7&&PopUpPrint("0x%X;",0x123456789ABCDEF0)==0x123456789ABCDEF0;}', []),
    ('I64 PPString(){return PopUpPrint("%s%d%c","6*",7,59)==42;}', []),
    ('I64 PPQuote(){return PopUpPrint("StrLen(\\"%Q\\");","a\\"b")==3;}', []),
    ('I64 PPFloat(){return PopUpPrint("ToI64(2*(%.4f));",1.5)==3;}', []),
    ('I64 PPHeap(){I64 b=Fs->data_heap->used_u8s,i;for(i=0;i<3;i++)if(!PPValue)return 0;return Fs->data_heap->used_u8s==b;}', []),
    ('PPValue;', ['1']),
    ('PPWide;', ['1']),
    ('PPString;', ['1']),
    ('PPQuote;', ['1']),
    ('PPFloat;', ['1']),
    ('PPHeap;', ['1']),
    ('6*7;', ['42']),
]

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
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    args = parser.parse_args()
    source, out = args.disk.resolve(), args.out.resolve()
    commands = list(COMMANDS)
    if out.exists():
        parser.error('Use a fresh output directory')
    sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    runner = ROOT/'tools/i386-kernel-input.py'
    pins = {str(p):sha(p) for p in [source, runner, ROOT/'Kernel/FontStd.HC', Path(__file__).resolve()]}
    out.mkdir(parents=True)
    working = out/'working.img'
    shutil.copyfile(source, working)
    report = dict(result='running', scope='Public PopUpPrint executes variadically formatted source in a real servant: decimal arithmetic, negative/wide results, mixed string/number/character, quoted string, software-floating formatted input and caller-heap recovery; not menu UI or cancellation',
                  input_sha256=pins, commands=serializable(commands), ram_mib=args.ram_mib)
    try:
        report['behavior'] = runpy.run_path(str(runner))['run_input'](
            working, out/'qemu', snapshot=False, ram_mib=args.ram_mib,
            cpu='486,-fpu', accel='tcg', qmp_stdio=True,
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
