#!/usr/bin/env python3
"""Check real boot-stage flags and shared U32 run-level state across tasks."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
ROOT=Path(__file__).resolve().parents[1]

def verify_stages(log):
    stages=[line.split()[2:] for line in log.splitlines() if line.startswith('RUN LEVEL ')]
    expected=[];value=0
    for name,bits in [('boot',7),('compiler',1<<12),('files',1<<10),('raw',1<<8),('adam',1<<18),('interrupts',1<<9),('doc',1<<13),('registry',1<<15),('winmgr',1<<14)]:
        value|=bits;expected.append([name,f'{value:016X}'])
    if stages!=expected:raise ValueError('Unexpected run-level transitions: '+repr(stages))
    boundaries=[('compiler','PUBLIC MATH BOUND\n'),('files','FILES '),('adam','CONSOLE TASK SPAWNED\n'),('interrupts','CONSOLE TASK SPAWNED\n'),('doc','STARTUP source begin\n'),('registry','RUN LEVEL doc '),('winmgr','STARTUP source begin\n')]
    for stage,marker in boundaries:
        if log.index('RUN LEVEL '+stage+' ')<log.index(marker):raise ValueError('Stage published before its readiness boundary: '+stage)
    return dict(transitions=stages,final_value=value)

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);ap.add_argument('--ram-mib',type=int,choices=(8,64),default=64);args=ap.parse_args()
    out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-run-level/Contract.HC'
    paths=[args.disk.resolve(),Path(__file__).resolve(),fixture]+[ROOT/p for p in ['tools/build-i386-kernel.py','tools/package-i386-native-image.py','tools/i386-kernel-input.py','Kernel/FontStd.HC','Kernel/RunLevelTypes.HH','Kernel/I386/ConsoleRuntime.HH']]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Real native stage ordering and flags, U32 data binding, shared child read/write and parent restoration, resumed console and exact VGA; no autocomplete activation, unsupported architecture stage or full release qualification')
    try:
        image=out/'working.img'
        runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),image,additions={'/RunLevelContract.HC':fixture.read_bytes()})
        report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](image,out/'behavior',ram_mib=args.ram_mib,accel='kvm',cpu='486,-fpu',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check=dict(status='ok',answers=[],pause_window_manager=False,commands=[('#include "C:/RunLevelContract.HC"',[]),('RunLevelContract;',['7']),('sys_run_level;',['325383']),('6*7;',['42'])]))
        report['stages']=verify_stages((out/'behavior/debug.log').read_text())
        build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
        if build['mutated_file_contents'](image,{'/RunLevelContract.HC'})['/RunLevelContract.HC']!=fixture.read_bytes():raise ValueError('Fixture changed')
        report['filesystem_integrity']=build['verify_mutated_volume'](image)
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
