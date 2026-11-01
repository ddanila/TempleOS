#!/usr/bin/env python3
"""Measure alternating isolated 8 MiB startup on two pinned images."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]
RUNNER=ROOT/'tools/i386-kernel-input.py'


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('control',type=Path)
    parser.add_argument('candidate',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    paths={'control':args.control.resolve(),'candidate':args.candidate.resolve()}
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in [*paths.values(),RUNNER,ROOT/'Kernel/FontStd.HC',Path(__file__).resolve()]}
    out.mkdir(parents=True)
    report=dict(result='running',scope='Alternating isolated boot-to-prompt timings; no full interactive or desktop qualification',
                input_sha256=pins,runs=[])
    try:
        run=runpy.run_path(str(RUNNER))['run_input']
        for index,name in enumerate(('control','candidate','candidate','control')):
            result=run(paths[name],out/f'{index}-{name}',cpu='486,-fpu',ram_mib=8,
                       qmp_stdio=True,welcome=True,
                       startup_check={'status':'ok','answers':[],'commands':[],
                                      'pause_window_manager':False})
            report['runs'].append(dict(image=name,startup_seconds=result['startup_seconds']))
            print(name, result['startup_seconds'],flush=True)
            (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(Path(name).is_file() and sha(Path(name))==digest
                                       for name,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
