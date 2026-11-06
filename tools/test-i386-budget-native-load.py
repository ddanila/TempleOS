#!/usr/bin/env python3
"""Load Budget with its reviewed pointer-width port and verify installation."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--load-settings',action='store_true',help='Load the real autocomplete and settings libraries into Adam before the app');ap.add_argument('--require-bundled',action='store_true');ap.add_argument('--accel',choices=('tcg','kvm'),default='tcg');args=ap.parse_args()
    out=args.out.resolve();source=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True);image=out/'working.img'
    helper=ROOT/'tools/test-i386-timeclock-welcome.py';packager=ROOT/'tools/package-i386-native-image.py';inventory=ROOT/'docs/i386-compatibility-inventory.json'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths=[ROOT/'tools/i386-budget-source.py',source,Path(__file__).resolve(),helper,packager,inventory,ROOT/'tools/build-i386-kernel.py',ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Budget with reviewed I64 sort slots: source load, repeated Install, physical archive and guest-expanded template on native 64 MiB; not application workflow qualification')
    try:
        entries=[e for e in json.loads(inventory.read_text())['entries'] if e['path'].startswith('Apps/Budget/')]
        pack=runpy.run_path(str(packager));initial_files=pack['snapshot'](source.read_bytes())[1]
        additions={};expected={}
        budget_source=runpy.run_path(str(ROOT/'tools/i386-budget-source.py'))['budget_source']
        report['source_ports']=['Apps/Budget/BgtStrs.HC: explicit I64 sort slots']
        for e in entries:
            data=budget_source(e)
            name='/'+e['path'];expected[name]=data
            if name in initial_files:
                if initial_files[name][2]!=data:raise ValueError('Bundled Budget differs: '+name)
            elif args.require_bundled:raise ValueError('Budget file is not bundled: '+name)
            else:additions[name]=data
        archive_name='/Apps/Budget/Accts.DD.Z'
        if archive_name not in initial_files or initial_files[archive_name][0]!=0xC00:
            raise ValueError('Bundled compressed accounts template missing')
        report['template_archive_sha256']=hashlib.sha256(initial_files[archive_name][2]).hexdigest()
        report['added_app_files']=sorted(additions)
        report['bundled_app_files']=len(expected)-len(additions)
        commands=[]
        if args.load_settings:
            for name in ('Adam/AutoComplete/MakeAC.HC','Adam/AutoComplete/ACFill.HC','Adam/AutoComplete/ACTask.HC','Adam/AutoComplete/ACInit.HC','Adam/TaskSettings.HC','Adam/TaskSettingsCore.HC'):
                path=ROOT/name;pins[str(path)]=sha(path)
                if initial_files['/'+name][2]!=path.read_bytes():raise ValueError('Shipped dependency differs: '+name)
            commands += ['AdamFile("C:/Adam/AutoComplete/MakeAC.HC",FALSE);','AdamFile("C:/Adam/TaskSettings.HC",FALSE);']
        commands += ['#include "C:/Apps/Budget/Load.HC"','#include "C:/Apps/Budget/Install.HC"',
                     '#include "C:/Apps/Budget/Install.HC"',
                     'U0 BudgetTemplateRead(){I64 n;U8 *s=FileRead("C:/Budget/Accts.DD.Z",&n);if(!s)throw(1,TRUE);FileWrite("C:/BudgetTemplate.DATA",s,n);Free(s);}BudgetTemplateRead;',
                     '6*7;']
        report['commands']=commands
        report['packaging']=pack['package'](source,image,additions=additions)
        runpy.run_path(str(helper))['guest'](image,out/'guest',commands,64,True,accel=args.accel)
        snapshot=runpy.run_path(str(packager))['snapshot']
        _,files,dirs=snapshot(image.read_bytes())
        if '/Budget' not in dirs:raise ValueError('Budget installation directory missing')
        installed=files.get('/Budget/Accts.DD.Z')
        if not installed or installed != initial_files[archive_name]:
            raise ValueError('Installed archive bytes/attributes/date differ from bundled template')
        if files.get('/BudgetTemplate.DATA', (0,0,None))[2] != expected['/Apps/Budget/Accts.DD']:
            raise ValueError('Guest-expanded installed template differs from original')
        report['installed_template_sha256']=hashlib.sha256(files['/BudgetTemplate.DATA'][2]).hexdigest()
        for name,data in expected.items():
            if files[name][2]!=data:raise ValueError('Delivered Budget source changed: '+name)
        allowed=set(additions)|{'/Budget/Accts.DD.Z','/BudgetTemplate.DATA'}
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
