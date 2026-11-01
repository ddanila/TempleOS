#!/usr/bin/env python3
"""Package and load an unchanged original application on the native port."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

ROOT=Path(__file__).resolve().parents[1]
REPAIRS='ce055f205fc38536443289fb1cfc73632f6624f4'

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--app',required=True,choices=('Logic','KeepAway','Strut','Vocabulary'));ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();source=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True);image=out/'working.img'
    helper=ROOT/'tools/test-i386-timeclock-welcome.py';packager=ROOT/'tools/package-i386-native-image.py';inventory=ROOT/'docs/i386-compatibility-inventory.json'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths=[source,Path(__file__).resolve(),helper,packager,inventory,ROOT/'Kernel/FontStd.HC',ROOT/'tools/build-i386-kernel.py']
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Original application Load on native 64 MiB; not startup or application workflow qualification',app=args.app)
    try:
        entries=[e for e in json.loads(inventory.read_text())['entries'] if e['path'].startswith('Apps/'+args.app+'/')]
        additions={}
        for e in entries:
            data=subprocess.check_output(['git','show',REPAIRS+':'+e['path']],cwd=ROOT)
            if hashlib.sha256(data).hexdigest()!=e['reference_sha256']:raise ValueError('Reference mismatch: '+e['path'])
            additions['/'+e['path']]=data
        # Full-content images may already contain the original files. Verify
        # every existing byte before retaining it; only add absent paths.
        existing=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](source,set(additions))
        for name,data in existing.items():
            if data!=additions[name]:raise ValueError('Existing application file differs from reference: '+name)
        report['verified_existing']={name:hashlib.sha256(data).hexdigest() for name,data in existing.items()}
        missing={name:data for name,data in additions.items() if name not in existing}
        report['packaging']=runpy.run_path(str(packager))['package'](source,image,additions=missing)
        delivered=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](image,set(additions))
        if delivered!=additions:raise ValueError('Packaged application differs from reference')
        report['delivered_sha256']={name:hashlib.sha256(data).hexdigest() for name,data in delivered.items()}
        runpy.run_path(str(helper))['guest'](image,out/'guest',['#include "C:/Apps/'+args.app+'/Load.HC"','6*7;'],64,True)
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
