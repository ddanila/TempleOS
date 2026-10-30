#!/usr/bin/env python3
"""Compare nested settings restoration on another task."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?')
    parser.add_argument('--shared',action='store_true',help='Use current shared original settings sources')
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if args.disk and args.shared:parser.error('--shared is only for the original-system run')
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-task-settings-remote/Contract.HC'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[Path(__file__).resolve(),fixture]
    report=dict(result='running',mode='native' if args.disk else 'shared' if args.shared else 'pinned-original',
                scope='Nested settings stack and restoration of attributes, scrolling and title on a separately spawned task; not directory, palette, audio, autocomplete, cancellation or failure cleanup')
    if args.disk:
        inputs += [args.disk.resolve()]+[ROOT/n for n in ('tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/i386-kernel-input.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC')]
    else:
        inputs += [ROOT/n for n in ('tools/test-i386-timeclock-reference.py','tools/build-iso.py','tools/guest-run.py')]
        reference=runpy.run_path(str(inputs[-3]))
        overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=reference['restore_reference'](overlay)
        if args.shared:
            for name in ('Adam/TaskSettings.HC','Adam/TaskSettingsCore.HC'):
                path=ROOT/name;inputs.append(path)
                target=overlay/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(path.read_bytes())
    report['input_sha256']={str(p):sha(p) for p in inputs}
    try:
        if args.disk:
            disk=out/'working.img'
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={'/Settings.HC':fixture.read_bytes()})
            commands=['#include "C:/Settings.HC"',"if(SettingsRemoteContract!=31)throw('Settings',TRUE);",'6*7;']
            runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](disk,out/'guest',commands,args.ram_mib,True)
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,{'/Settings.HC'})
            if files['/Settings.HC']!=fixture.read_bytes():raise ValueError('Delivered fixture changed')
        else:
            source=fixture.read_bytes()+b'\nU0 FQReport(U8*s){while(*s)OutU8(0xE9,*s++);}\n'
            source+=b'I64 fq_result=SettingsRemoteContract;U8 *fq_line=MStrPrint("SETTINGS REMOTE MASK %d\\n",fq_result);FQReport(fq_line);Free(fq_line);FQReport("DONE settings remote\\n");\n'
            (overlay/'Once.HC').write_bytes(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if 'SETTINGS REMOTE MASK 31\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original remote settings contract failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==d for p,d in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
