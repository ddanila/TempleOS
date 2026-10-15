#!/usr/bin/env python3
"""Require real popup servant execution, synchronous results and asynchronous retirement."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT = Path(__file__).resolve().parents[1]
COMMANDS = [
    ('CTask *pu_child;I64 pu_value;Bool pu_release;', []),
    ('I64 PUSync(){CTask *t=NULL;I64 r=PopUp("6*7;",Fs,&t);return r==42&&!t&&!Fs->popup_task;}', []),
    ('I64 PUWide(){return PopUp("-7;",Fs)==-7&&PopUp("0x123456789ABCDEF0;",Fs)==0x123456789ABCDEF0;}', []),
    ('U8 *PUAsyncSource(){return MStrPrint("while(!*0x%X(Bool *))Yield;*0x%X(I64 *)=42;",&pu_release,&pu_value);}', []),
    ('I64 PUAsyncStart(){I64 r;U8 *s;pu_release=FALSE;pu_value=0;pu_child=NULL;s=PUAsyncSource;r=PopUp(s,NULL,&pu_child);Free(s);return !r&&TaskValidate(pu_child)&&!Fs->popup_task;}', []),
    ('I64 PUAsyncFinish(){pu_release=TRUE;while(TaskValidate(pu_child))Yield;return pu_value==42&&pu_child!=NULL;}', []),
    ('I64 PUHeap(){I64 b=Fs->data_heap->used_u8s,i;for(i=0;i<3;i++)if(!PUSync)return 0;for(i=0;i<32;i++)Yield;return Fs->data_heap->used_u8s==b;}', []),
    ('PUSync;', ['1']), ('PUWide;', ['1']), ('PUAsyncStart;', ['1']),
    ('PUAsyncFinish;', ['1']), ('PUHeap;', ['1']), ('6*7;', ['42'])]

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
    report = dict(result='running', scope='Public PopUp: servant executes copied source, synchronous return42, negative/wide results, async child survives return then retires, output-pointer rules and repeated caller-heap recovery; not popup menu/UI, cancellation or arbitrary owner retirement',
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
