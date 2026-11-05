#!/usr/bin/env python3
"""Run the unchanged registry demo twice in one boot with a real document reload."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct

ROOT=Path(__file__).resolve().parents[1]


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('disk',type=Path);p.add_argument('--reference',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True);p.add_argument('--require-bundled',action='store_true')
    args=p.parse_args();source=args.disk.resolve();ref=args.reference.resolve();out=args.out.resolve()
    if out.exists():p.error('Use a fresh output directory')
    reference=json.loads((ref/'result.json').read_text());demo=ROOT/'Demo/RegistryDemo.HC'
    sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
    if reference.get('result')!='pass' or not reference.get('inputs_unchanged') or reference.get('repeat_value')!=1236:
        raise ValueError('Passing original same-boot repeat reference required')
    if sha(demo)!=reference['reference_sha256']['Demo/RegistryDemo.HC']:
        raise ValueError('Demo differs from original')
    first_tool=ROOT/'tools/test-i386-registry-demo.py'
    paths=[source,demo,ref/'result.json',ref/'guest/demo-registry.HC',ref/'guest/repeat-output.DD',
        ref/'guest/repeat-record.bin',Path(__file__).resolve(),first_tool,ROOT/'tools/i386-kernel-input.py',
        ROOT/'tools/build-i386-kernel.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
    pins={str(f):sha(f) for f in paths};out.mkdir(parents=True);working=out/'working.img'
    report=dict(result='fail',input_sha256=pins,commands=[],
        scope='Two unchanged RegistryDemo launches in one 64 MiB KVM 486 without FPU/live WinMgr boot, actual registry document reload, exact pixels and persisted state/time/filesystem checks. Does not substitute reboot for warm redefinition or qualify all registry APIs.')
    try:
        pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        initial_files=pack['snapshot'](source.read_bytes())[1]
        existing=initial_files.get('/Demo/RegistryDemo.HC')
        if existing is not None and existing[2]!=demo.read_bytes():raise ValueError('Bundled demo differs')
        if args.require_bundled and existing is None:raise ValueError('RegistryDemo is not bundled')
        report['demo_source']='bundled' if existing is not None else 'added-fixture'
        report['packaging']=pack['package'](source,working,additions={} if existing else {'/Demo/RegistryDemo.HC':demo.read_bytes()})
        extract=build['mutated_file_contents'];names={'/DemoRegistryState.HC','/DemoTimes.DATA','/Demo/RegistryDemo.HC'}
        def saved_state(expected):
            files=extract(working,names)
            if files['/Demo/RegistryDemo.HC']!=demo.read_bytes():raise ValueError('Demo changed')
            before,score,after=struct.unpack('<3d',files['/DemoTimes.DATA'])
            state=files['/DemoRegistryState.HC'];match=re.search(rb'F64 best_score= *([0-9]+\.[0-9]{5});\n',state)
            if not 0<=before<=score<=after or not match or abs(float(match[1])-score)>0.0000051 or (str(expected)+';\n').encode() not in state:
                raise ValueError('Persisted increment, score or actual time bounds differ')
            return dict(value=expected,score=score,time_bounds=[before,after],stored_score=match[1].decode(),
                state_sha256=hashlib.sha256(state).hexdigest())
        base=runpy.run_path(str(first_tool))['COMMANDS']
        class Commands:
            def __len__(self):return len(report['commands'])
            def __iter__(self):
                def emit(command):
                    if len(command[0])>255:raise ValueError('Command exceeds input buffer')
                    report['commands'].append(command);return command
                for command in base[:-1]:yield emit(command)
                #Each prior command has completed. FileWrite uses synchronous ATA
                #writes; read its acknowledged saved bytes while the guest is idle.
                report['first']=saved_state(1235)
                yield emit(('U0 WarmReload(){CDoc *old=sys_registry_doc;sys_registry_doc=DocRead("C:/Registry.HC.Z");if(!sys_registry_doc)throw(\'Delib\',TRUE);DocDel(old);}WarmReload;',[]))
                yield emit(('RegExe("DemoCompany/Game1/SimpleVal")==1235;',['1']))
                for command,answers in base[1:]:
                    if command.startswith('#include "C:/Demo/'):
                        answers=['High Score:'+report['first']['stored_score'],'Val:1235']
                    yield emit((command.replace('==1235','==1236'),answers))
        report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
            working,out/'qemu',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='kvm',qmp_stdio=True,
            welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],
                'commands':Commands(),'pause_window_manager':False,'command_timeout':120})
        report['second']=saved_state(1236)
        final_files=pack['snapshot'](working.read_bytes())[1]
        allowed={'/Registry.HC.Z','/DemoRegistryState.HC','/DemoTimes.DATA'}
        if existing is None:allowed.add('/Demo/RegistryDemo.HC')
        changed={name for name in set(initial_files)|set(final_files) if initial_files.get(name)!=final_files.get(name)}
        if changed-allowed:raise ValueError('Unrelated files changed: '+repr(sorted(changed-allowed)))
        report.update(result='pass',changed_files=sorted(changed),preserved_source_files=len(set(initial_files)-allowed),
            filesystem=build['verify_mutated_volume'](working))
    except Exception as exc:
        report['error']=str(exc);raise
    finally:
        report['inputs_unchanged']=all(sha(Path(f))==h for f,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Same-boot RegistryDemo repeat failed')


if __name__=='__main__':main()
