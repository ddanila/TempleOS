#!/usr/bin/env python3
"""Package and load the unchanged original Budget source on the native port."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

ROOT=Path(__file__).resolve().parents[1]
REPAIRS='ce055f205fc38536443289fb1cfc73632f6624f4'

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();source=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True);image=out/'working.img'
    helper=ROOT/'tools/test-i386-timeclock-welcome.py';packager=ROOT/'tools/package-i386-native-image.py';inventory=ROOT/'docs/i386-compatibility-inventory.json'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths=[source,Path(__file__).resolve(),helper,packager,inventory,ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Original Budget source load and Install on native 64 MiB; not application workflow qualification')
    try:
        entries=[e for e in json.loads(inventory.read_text())['entries'] if e['path'].startswith('Apps/Budget/')]
        additions={}
        for e in entries:
            data=subprocess.check_output(['git','show',REPAIRS+':'+e['path']],cwd=ROOT)
            if hashlib.sha256(data).hexdigest()!=e['reference_sha256']:raise ValueError('Reference mismatch: '+e['path'])
            additions['/'+e['path']]=data
        report['packaging']=runpy.run_path(str(packager))['package'](source,image,additions=additions)
        runpy.run_path(str(helper))['guest'](image,out/'guest',['#include "C:/Apps/Budget/Load.HC"','#include "C:/Apps/Budget/Install.HC"','6*7;'],64,True)
        snapshot=runpy.run_path(str(packager))['snapshot']
        _,files,dirs=snapshot(image.read_bytes())
        if '/Budget' not in dirs:raise ValueError('Budget installation directory missing')
        if not any(name in files for name in ('/Budget/Accts.DD','/Budget/Accts.DD.Z')):raise ValueError('Installed accounts missing')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
