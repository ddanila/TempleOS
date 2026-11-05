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
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--load-settings',action='store_true',help='Load the real autocomplete and settings libraries into Adam before the app');ap.add_argument('--require-bundled',action='store_true');ap.add_argument('--accel',choices=('tcg','kvm'),default='tcg');args=ap.parse_args()
    out=args.out.resolve();source=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True);image=out/'working.img'
    helper=ROOT/'tools/test-i386-timeclock-welcome.py';packager=ROOT/'tools/package-i386-native-image.py';inventory=ROOT/'docs/i386-compatibility-inventory.json'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths=[source,Path(__file__).resolve(),helper,packager,inventory,ROOT/'tools/build-i386-kernel.py',ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Original Budget source load and Install on native 64 MiB; not application workflow qualification')
    try:
        entries=[e for e in json.loads(inventory.read_text())['entries'] if e['path'].startswith('Apps/Budget/')]
        pack=runpy.run_path(str(packager));initial_files=pack['snapshot'](source.read_bytes())[1]
        additions={};expected={}
        for e in entries:
            data=subprocess.check_output(['git','show',REPAIRS+':'+e['path']],cwd=ROOT)
            if hashlib.sha256(data).hexdigest()!=e['reference_sha256']:raise ValueError('Reference mismatch: '+e['path'])
            name='/'+e['path'];expected[name]=data
            if name in initial_files:
                if initial_files[name][2]!=data:raise ValueError('Bundled Budget differs: '+name)
            elif args.require_bundled:raise ValueError('Budget file is not bundled: '+name)
            else:additions[name]=data
        report['added_app_files']=sorted(additions)
        report['bundled_app_files']=len(expected)-len(additions)
        commands=[]
        if args.load_settings:
            for name in ('Adam/AutoComplete/MakeAC.HC','Adam/AutoComplete/ACFill.HC','Adam/AutoComplete/ACTask.HC','Adam/AutoComplete/ACInit.HC','Adam/TaskSettings.HC','Adam/TaskSettingsCore.HC'):
                path=ROOT/name;pins[str(path)]=sha(path)
                if initial_files['/'+name][2]!=path.read_bytes():raise ValueError('Shipped dependency differs: '+name)
            commands += ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);']
        commands += ['#include "C:/Apps/Budget/Load.HC"','#include "C:/Apps/Budget/Install.HC"','6*7;']
        report['commands']=commands
        report['packaging']=pack['package'](source,image,additions=additions)
        runpy.run_path(str(helper))['guest'](image,out/'guest',commands,64,True,accel=args.accel)
        snapshot=runpy.run_path(str(packager))['snapshot']
        _,files,dirs=snapshot(image.read_bytes())
        if '/Budget' not in dirs:raise ValueError('Budget installation directory missing')
        if not any(name in files for name in ('/Budget/Accts.DD','/Budget/Accts.DD.Z')):raise ValueError('Installed accounts missing')
        for name,data in expected.items():
            if files[name][2]!=data:raise ValueError('Delivered Budget source changed: '+name)
        allowed=set(additions)|{'/Budget/Accts.DD','/Budget/Accts.DD.Z'}
        changed={name for name in set(initial_files)|set(files) if initial_files.get(name)!=files.get(name)}
        if changed-allowed:raise ValueError('Unrelated files changed: '+repr(sorted(changed-allowed)))
        report['changed_files']=sorted(changed)
        report['preserved_source_files']=len(set(initial_files)-allowed)
        report['filesystem']=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume'](image)
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
