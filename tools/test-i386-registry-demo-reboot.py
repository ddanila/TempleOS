#!/usr/bin/env python3
"""Run unchanged RegistryDemo on two persisted boots, then verify a third boot."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import shutil
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--reference',type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args();source=args.disk.resolve();ref=args.reference.resolve();out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    reference=json.loads((ref/'result.json').read_text())
    if reference.get('result')!='pass' or not reference.get('inputs_unchanged') or reference.get('repeat_value')!=1236:
        raise ValueError('Passing original repeated-launch reference required')
    first_tool=ROOT/'tools/test-i386-registry-demo.py'
    paths=[source,Path(__file__).resolve(),first_tool,ref/'result.json',
        ROOT/'Demo/RegistryDemo.HC',ROOT/'tools/i386-kernel-input.py',
        ROOT/'tools/build-i386-kernel.py',ROOT/'tools/package-i386-native-image.py']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths};out.mkdir(parents=True)
    report=dict(result='fail',input_sha256=pins,
        scope='Unchanged RegistryDemo first launch, second launch after real persisted reboot, and third-boot reload; 64 MiB KVM 486 without FPU/live WinMgr, exact pixels and filesystem checks. Original reference covers document reload, not original machine reboot.')
    try:
        subprocess.run(['python3',str(first_tool),str(source),'--reference',str(ref),
            '--out',str(out/'first')],cwd=ROOT,check=True)
        first=json.loads((out/'first/result.json').read_text())
        if first['result']!='pass' or not first['inputs_unchanged']:raise ValueError('First launch failed')
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        extract=build['mutated_file_contents'];verify=build['verify_mutated_volume']
        initial=extract(out/'first/working.img',{'/DemoRegistryState.HC'})['/DemoRegistryState.HC']
        old=re.search(rb'F64 best_score= *([0-9]+\.[0-9]{5});\n',initial)
        if not old:raise ValueError('Missing first-launch persisted score')
        expected_score=old[1].decode()
        working=out/'working.img';shutil.copyfile(out/'first/working.img',working)
        run=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        commands=runpy.run_path(str(first_tool))['COMMANDS']
        second=[]
        for command,answers in commands:
            if command.startswith('#include "C:/Demo/'):
                answers=['High Score:'+expected_score,'Val:1235']
            second.append((command.replace('==1235','==1236'),answers))
        report['second_commands']=second
        def boot(commands,name):
            return run(working,out/name,snapshot=False,ram_mib=64,cpu='486,-fpu',accel='kvm',
                qmp_stdio=True,welcome=True,keep_window_manager=True,
                startup_check={'status':'ok','answers':[],'commands':commands,
                    'pause_window_manager':False,'command_timeout':120})
        report['second']=boot(second,'second')
        files=extract(working,{'/DemoRegistryState.HC','/DemoTimes.DATA','/Demo/RegistryDemo.HC'})
        if files['/Demo/RegistryDemo.HC']!=(ROOT/'Demo/RegistryDemo.HC').read_bytes():raise ValueError('Demo changed')
        before,score,after=struct.unpack('<3d',files['/DemoTimes.DATA'])
        state=files['/DemoRegistryState.HC']
        match=re.search(rb'F64 best_score= *([0-9]+\.[0-9]{5});\n',state)
        if not 0<=before<=score<=after or not match or abs(float(match[1])-score)>0.0000051 or b'1236;\n' not in state:
            raise ValueError('Second launch persisted state/time differs')
        report['second_filesystem']=verify(working)
        third=[('#include "/Kernel/I386/PublicUser.HH"',[]),
            ('RegExe("DemoCompany/Game1/SimpleVal")==1236;',['1']),
            ('RegExe("DemoCompany/Game1")==1236;',['1']),
            ('Abs(best_score-('+match[1].decode()+'))<0.00000001;',['1']),
            ('6*7;',['42'])]
        report['third_commands']=third;report['third']=boot(third,'third')
        after_files=extract(working,{'/DemoRegistryState.HC','/DemoTimes.DATA','/Demo/RegistryDemo.HC'})
        if after_files!=files:raise ValueError('Third-boot verification changed saved files')
        report.update(result='pass',second_score=score,second_time_bounds=[before,after],
            persisted_sha256=hashlib.sha256(state).hexdigest(),filesystem=verify(working))
    except Exception as exc:
        report['error']=str(exc);raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Registry demo reboot workflow failed')


if __name__=='__main__':main()
