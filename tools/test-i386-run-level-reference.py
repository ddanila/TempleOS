#!/usr/bin/env python3
"""Observe original run-level width, export binding, readiness and shared writes."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-run-level/Reference.HC';manifest=ROOT/'build/rebuild-test/result.json';snapshot=json.loads(manifest.read_text())
    if snapshot.get('result')!='pass':raise ValueError('Qualified original rebuild required')
    paths=[Path(__file__).resolve(),fixture,manifest]+[ROOT/p for p in ['Kernel/KernelB.HH','Kernel/RunLevelTypes.HH','Kernel/HashExportTypes.HH','tools/build-iso.py','tools/guest-run.py']]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    for name,relative in [('Kernel.BIN','0000Boot/0000Kernel.BIN.C'),('Compiler.BIN','Compiler/Compiler.BIN')]:
        p=ROOT/'build/rebuild-test/overlay'/relative
        if sha(p)!=snapshot['generations'][-1][name]:raise ValueError('Rebuild binary mismatch')
        paths.append(p)
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Rebuilt-original U32 run-level export, actual compiler/block/document/registry readiness at the Once hook before Adam-server readiness, child reads and writes to actual shared state, restoring flags. Original architecture profile; no autocomplete workflow or native stage-order equivalence claim.')
    try:
        overlay=out/'overlay';overlay.mkdir()
        suffix=b'\nU0 RLReport(U8*s){while(*s)OutU8(0xE9,*s++);}\nI64 rl_mask=RunLevelReferenceContract;U8 *rl_state=MStrPrint("RUN LEVEL ORIGINAL FLAGS %X\\n",sys_run_level);RLReport(rl_state);Free(rl_state);U8 *rl_line=MStrPrint("RUN LEVEL REFERENCE %d\\n",rl_mask);RLReport(rl_line);Free(rl_line);RLReport("DONE run level reference\\n");\n'
        (overlay/'Once.HC').write_bytes(fixture.read_bytes()+suffix);iso=out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
        if 'RUN LEVEL REFERENCE 7\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original reference did not pass')
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
