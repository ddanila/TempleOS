#!/usr/bin/env python3
"""Require exact terminal tail pixels after output crosses the screen boundary."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT=Path(__file__).resolve().parents[1]


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--force-full',action='store_true',help='Start with full refresh enabled and require that flag to survive presentation')
    ap.add_argument('--live',action='store_true',help='Keep WinMgr running instead of suspending it')
    ap.add_argument('--accel',choices=['tcg','kvm'],default='tcg')
    args=ap.parse_args();out=args.out.resolve();source=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir();working=out/'candidate.img';shutil.copyfile(source,working)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths=[source,Path(__file__).resolve(),ROOT/'tools/i386-kernel-input.py',ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,accel=args.accel,ram_mib=8,live_window_manager=args.live,initial_full_refresh=args.force_full,
                scope='Exact 60-row tail after 65 output lines, then subsequent arithmetic; not whole desktop qualification')
    commands=[('U0 ScrollBurst(){I64 i;for(i=0;i<65;i++)"%d\\n",i;}',[]),
              ('ScrollBurst;',[str(i) for i in range(65)]),('6*7;',['42'])]
    if args.force_full:commands.insert(0,('U0 ScrollForce(){DocPut->flags|=DOCF_DO_FULL_REFRESH;}ScrollForce;',[]))
    commands.append(('(DocPut->flags&DOCF_DO_FULL_REFRESH)!=0;',['1' if args.force_full else '0']))
    try:
        report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
            working,out/'guest',snapshot=False,cpu='486,-fpu',ram_mib=8,accel=args.accel,
            qmp_stdio=True,welcome=True,startup_check={'status':'ok','answers':[],'commands':commands,
                'pause_window_manager':not args.live,'command_timeout':180})
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
