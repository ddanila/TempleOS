#!/usr/bin/env python3
"""Load unchanged original AutoComplete source on a native image."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();source=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True);image=out/'working.img'
    helper=ROOT/'tools/test-i386-timeclock-welcome.py';build=ROOT/'tools/build-i386-kernel.py';inventory=ROOT/'docs/i386-compatibility-inventory.json'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths=[source,Path(__file__).resolve(),helper,build,inventory,ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Compile and execute original AutoComplete MakeAC sources; dictionary assets, initialization, visible suggestions and full application behavior are not qualified')
    try:
        expected={('/'+e['path']):e['reference_sha256'] for e in json.loads(inventory.read_text())['entries'] if e['path'].startswith('Adam/AutoComplete/') and e['path'].endswith('.HC')}
        read=runpy.run_path(str(build))['mutated_file_contents'];files=read(source,set(expected))
        if {name:hashlib.sha256(data).hexdigest() for name,data in files.items()}!=expected:raise ValueError('AutoComplete source differs from original')
        shutil.copyfile(source,image)
        runpy.run_path(str(helper))['guest'](image,out/'guest',['#include "C:/Adam/AutoComplete/MakeAC.HC"','6*7;'],64,True)
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
