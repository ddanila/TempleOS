#!/usr/bin/env python3
"""Verify seeded registry defaults, missing-file creation and immutable reboot."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT=Path(__file__).resolve().parents[1]
REGISTRY='/Registry.HC.Z'


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args();source=args.disk.resolve();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True);working=out/'working.img'
    golden=ROOT/'tests/i386/startup-registry-reference.json'
    paths=[source,Path(__file__).resolve(),golden,ROOT/'tools/i386-kernel-input.py',
           ROOT/'tools/package-i386-native-image.py',ROOT/'tools/build-i386-kernel.py',ROOT/'Kernel/FontStd.HC']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths};expected=bytes.fromhex(json.loads(golden.read_text())['archive_hex'])
    snapshot=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['snapshot']
    build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
    run=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
    report=dict(result='fail',input_sha256=pins,scope='Three persisted 8 MiB KVM boots: seeded defaults, public deletion, actual missing-file initialization, then byte-identical reboot',boots=[])
    try:
        shutil.copyfile(source,working)
        _,baseline,directories=snapshot(working.read_bytes())
        if baseline.get(REGISTRY,(0,0,None))[0]!=0xC00 or baseline[REGISTRY][2]!=expected:
            raise ValueError('Seeded registry differs from original defaults')
        for phase in range(3):
            before=working.read_bytes()
            commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),
                ('sys_registry_doc->mem_task==adam_task && registry_version==sys_os_version && sys_msg_flags[0]==0;',['1'])]
            if phase==0:commands.append(('FileDel("C:/Registry.HC.Z");',['1']))
            commands.append(('6*7;',['42']))
            behavior=run(working,out/f'boot-{phase}',snapshot=False,ram_mib=8,cpu='486,-fpu',accel='kvm',
                qmp_stdio=True,welcome=True,keep_window_manager=True,
                startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False})
            after=working.read_bytes();_,files,dirs=snapshot(after)
            if dirs!=directories or {k:v for k,v in files.items() if k!=REGISTRY}!={k:v for k,v in baseline.items() if k!=REGISTRY}:
                raise ValueError('Registry workflow changed unrelated live files/metadata')
            if phase==0:
                if REGISTRY in files:raise ValueError('Public registry deletion did not persist')
            elif files.get(REGISTRY,(0,0,None))[0]!=0xC00 or files[REGISTRY][2]!=expected:
                raise ValueError('Missing-file startup did not recreate exact original archive')
            if phase==2 and after!=before:raise ValueError('Initialized registry reboot changed disk bytes')
            report['boots'].append(dict(phase=phase,behavior=behavior,filesystem=build['verify_mutated_volume'](working),
                disk_sha256=sha(working),disk_unchanged=before==after))
        report.update(result='pass',registry_sha256=hashlib.sha256(expected).hexdigest())
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Startup registry workflow failed')


if __name__=='__main__':main()
