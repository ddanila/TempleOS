#!/usr/bin/env python3
"""Run the public task accounting contract through small packaged source batches."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]
ACCOUNTING = ROOT/'tools/test-i386-public-task-accounting.py'
HELPER = ROOT/'tools/test-i386-timeclock-welcome.py'
PACKAGER = ROOT/'tools/package-i386-native-image.py'


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path)
    ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--ram-mib',type=int,choices=(8,64),default=8)
    args=ap.parse_args()
    source=args.disk.resolve();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in [source,Path(__file__).resolve(),ACCOUNTING,HELPER,PACKAGER,
          ROOT/'tools/build-i386-kernel.py',ROOT/'tools/i386-kernel-input.py',ROOT/'Kernel/FontStd.HC',
          ROOT/'tools/test-i386-public-tasks.py',ROOT/'tools/test-i386-public-task-descendants.py',
          ROOT/'tools/test-i386-public-task-exceptions.py',ROOT/'tools/test-i386-public-task-end-callbacks.py']}
    report=dict(result='running',input_sha256=pins,ram_mib=args.ram_mib,
        scope='Both bootstrap arenas recover across the existing public task lifecycle, descendant, exception, callback and rejection cases')
    try:
        commands,headers=runpy.run_path(str(ACCOUNTING))['behavior_commands'](source,args.ram_mib)
        additions={};calls=[];pending=[]
        def flush():
            if not pending:return
            name=f'/Acct{len(additions):02}.HC'
            additions[name]=(''.join(line+'\n' for line in pending)).encode('ascii')
            calls.append('#include "C:'+name+'"')
            pending.clear()
        for text,expected in commands:
            if expected:
                flush()
                if expected==['1']:
                    calls.append("if(!("+text.rstrip(';')+"))throw('Acct',TRUE);")
                elif text=='6*7;' and expected==['42']:
                    calls.append('6*7;')
                else:raise ValueError('Unsupported accounting expected result')
            else:
                pending.append(text)
                if len(pending)==5:flush()
        flush()
        if any(len(call)>255 for call in calls):raise ValueError('Command exceeds terminal input')
        working=out/'working.img'
        report['packaging']=runpy.run_path(str(PACKAGER))['package'](source,working,additions=additions)
        report['header_sha256']=headers
        report['batch_sha256']={name:hashlib.sha256(data).hexdigest() for name,data in additions.items()}
        report['command_count']=len(calls)
        runpy.run_path(str(HELPER))['guest'](working,out/'guest',calls,args.ram_mib,True,key_delay=.1,command_timeout=240)
        delivered=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](working,set(additions))
        if delivered!=additions:raise ValueError('Delivered accounting batches changed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
