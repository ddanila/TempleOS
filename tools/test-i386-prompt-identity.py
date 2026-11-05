#!/usr/bin/env python3
"""Check repeated first-command text before and after the first prompt scrolls away."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]
COMMANDS=[('GetRFlags&0x200;',['512']),('GetRFlags&0x200;',['512']),
          ('"'+'\\n'*64+'";',['']*64),('GetRFlags&0x200;',['512']),('6*7;',['42'])]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path);parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--runner',type=Path,default=ROOT/'tools/i386-kernel-input.py')
    args=parser.parse_args();out=args.out.resolve();source=args.disk.resolve();runner=args.runner.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths=[source,runner,Path(__file__).resolve(),ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths};report=dict(result='fail',input_sha256=pins,
        scope='Physical keyboard repeats identical initial command with retained first row and after 64 printed newlines retire it; all raster pixels and cursor variants checked at 8 MiB/live WinMgr',commands=COMMANDS)
    try:
        report['behavior']=runpy.run_path(str(runner))['run_input'](source,out/'qemu',
            ram_mib=8,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,keep_window_manager=True,
            startup_check={'status':'ok','answers':[],'commands':COMMANDS,'pause_window_manager':False})
        report['result']='pass'
    except Exception as exc:
        report['error']=str(exc);raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Prompt identity check failed')


if __name__=='__main__':main()
