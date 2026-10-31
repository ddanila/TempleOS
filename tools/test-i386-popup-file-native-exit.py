#!/usr/bin/env python3
"""Compare original and native synchronous PopUpFile Shift-Esc retirement."""
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
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if not args.disk:parser.error('Provide a native disk; use test-i386-popup-file-sync.py for the original reference')
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-popup-file/NativeExitContract.HC'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    input_case=ROOT/'tests/guest/i386-popup-file/PFCase.HC'
    inputs=[Path(__file__).resolve(),fixture,input_case]
    report=dict(result='running',mode='native' if args.disk else 'pinned-original',
                scope='Synchronous popup and caller retirement after Shift-Esc, observed by a sibling task')
    if args.disk:
        inputs += [args.disk.resolve()]+[ROOT/n for n in ('tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/i386-kernel-input.py','Kernel/FontStd.HC')]
    else:
        inputs += [ROOT/n for n in ('tools/test-i386-timeclock-reference.py','tools/build-iso.py','tools/guest-run.py')]
        reference=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
        overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=reference['restore_reference'](overlay)
    report['input_sha256']={str(p):sha(p) for p in inputs}
    try:
        if args.disk:
            disk=out/'working.img'
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={'/Probe/PopUpFileContract.HC':fixture.read_bytes(),'/Probe/PFCase.HC':input_case.read_bytes()})
            commands=[('#include "C:/Probe/PopUpFileContract.HC"',[]),('PFNativeStart;',['1']),('PFNativeWait;',['15'])]
            commands.append(('6*7;',['42']))
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](disk,out/'guest',snapshot=False,ram_mib=args.ram_mib,cpu='486,-fpu',accel='tcg',qmp_stdio=True,welcome=True,startup_check={'status':'ok','answers':[],'commands':commands,'command_timeout':120,'rejection_prefixes':('INPUT REJECT ',)})
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,{'/Probe/PopUpFileContract.HC','/Probe/PFCase.HC'})
            if files['/Probe/PopUpFileContract.HC']!=fixture.read_bytes() or files['/Probe/PFCase.HC']!=input_case.read_bytes():raise ValueError('Delivered fixture changed')
        else:
            source=fixture.read_bytes()+b'\nU0 FQReport(U8*s){while(*s)OutU8(0xE9,*s++);}\n'
            source+=b'I64 fq_result=PopUpFileContract;U8 *fq_line=MStrPrint("POPUPFILE MASK %d\\n",fq_result);FQReport(fq_line);Free(fq_line);FQReport("DONE POPUPFILE\\n");\n'
            (overlay/'Once.HC').write_bytes(source)
            (overlay/'Probe').mkdir(exist_ok=True)
            (overlay/'Probe/PFCase.HC').write_bytes(input_case.read_bytes())
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if 'POPUPFILE MASK 31\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original PopUpFile contract failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==d for p,d in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
