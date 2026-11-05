#!/usr/bin/env python3
"""Run the unchanged registry demo and verify displayed and persisted results."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import runpy
import struct

ROOT=Path(__file__).resolve().parents[1]
COMMANDS=[
    ('#include "/Kernel/I386/PublicUser.HH"',[]),
    ('F64 demo_before=tS;',[]),
    ('#include "C:/Demo/RegistryDemo.HC"',['High Score:1.23000','Val:1234']),
    ('F64 demo_after=tS;',[]),
    ('RegExe("DemoCompany/Game1/SimpleVal")==1235 && demo_before<=best_score && best_score<=demo_after;',['1']),
    ('U0 SaveDemoRegistry(){I64 n;U8 *p=FileRead("C:/Registry.HC.Z",&n);FileWrite("C:/DemoRegistryState.HC",p,n);Free(p);}',[]),
    ('U0 SaveDemoTimes(){F64 v[3];v[0]=demo_before;v[1]=best_score;v[2]=demo_after;FileWrite("C:/DemoTimes.DATA",v,24);}',[]),
    ('SaveDemoRegistry;SaveDemoTimes;',[]),
    ('6*7;',['42']),
]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--reference',type=Path,required=True)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--require-bundled',action='store_true',help='Require the unchanged demo in the source image')
    args=parser.parse_args();source=args.disk.resolve();out=args.out.resolve();ref=args.reference.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    if any(len(c[0])>255 for c in COMMANDS):raise ValueError('Demo command exceeds input buffer')
    report=json.loads((ref/'result.json').read_text());demo=ROOT/'Demo/RegistryDemo.HC'
    if report.get('result')!='pass' or not report.get('inputs_unchanged'):raise ValueError('Reference not qualified')
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    if sha(demo)!=report['reference_sha256']['Demo/RegistryDemo.HC']:raise ValueError('Demo differs from original reference')
    paths=[source,demo,ref/'result.json',ref/'guest/demo-record.bin',ref/'guest/demo-registry.HC',
        ref/'guest/demo-output.DD',Path(__file__).resolve(),ROOT/'tools/i386-kernel-input.py',
        ROOT/'tools/build-i386-kernel.py',ROOT/'tools/package-i386-native-image.py',ROOT/'Kernel/FontStd.HC']
    pins={str(p):sha(p) for p in paths};out.mkdir(parents=True);working=out/'working.img'
    report=dict(result='fail',input_sha256=pins,commands=COMMANDS,
        scope='Actual unchanged RegistryDemo first launch with fresh seeded defaults at 64 MiB; exact displayed values, time bounds, persisted increment/score, fixture identity and filesystem. No second boot or whole registry qualification')
    try:
        pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))
        existing=pack['snapshot'](source.read_bytes())[1].get('/Demo/RegistryDemo.HC')
        if existing is not None and existing[2]!=demo.read_bytes():raise ValueError('Bundled demo differs from original reference')
        if args.require_bundled and existing is None:raise ValueError('Source image does not bundle RegistryDemo')
        report['demo_source']='bundled' if existing is not None else 'added-fixture'
        report['packaging']=pack['package'](source,working,
            additions={} if existing is not None else {'/Demo/RegistryDemo.HC':demo.read_bytes()})
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](
            working,out/'qemu',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='kvm',qmp_stdio=True,
            welcome=True,keep_window_manager=True,startup_check={'status':'ok','answers':[],
                'commands':COMMANDS,'pause_window_manager':False,'command_timeout':120})
        files=build['mutated_file_contents'](working,{'/DemoRegistryState.HC','/DemoTimes.DATA','/Demo/RegistryDemo.HC'})
        if files.get('/Demo/RegistryDemo.HC')!=demo.read_bytes():raise ValueError('Persisted demo fixture changed')
        data=files.get('/DemoTimes.DATA',b'')
        if len(data)!=24:raise ValueError('Missing persisted time samples')
        before,score,after=struct.unpack('<3d',data)
        if not 0<=before<=score<=after:raise ValueError('Demo timestamp outside actual execution')
        state=files.get('/DemoRegistryState.HC',b'')
        match=re.search(rb'F64 best_score= *([0-9]+\.[0-9]{5});\n',state)
        if not match or abs(float(match[1])-score)>0.0000051 or b'1235;\n' not in state:
            raise ValueError('Persisted demo result differs')
        report.update(result='pass',score=score,time_bounds=[before,after],
            persisted_sha256=hashlib.sha256(state).hexdigest(),filesystem=build['verify_mutated_volume'](working))
    except Exception as exc:
        report['error']=str(exc);raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report['result']='fail'
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError('Registry demo workflow failed')


if __name__=='__main__':main()
