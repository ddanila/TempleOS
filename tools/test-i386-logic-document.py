#!/usr/bin/env python3
"""Compare Logic DolDoc binary records with their raw source."""
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
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-logic-document/Contract.HC'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[Path(__file__).resolve(),fixture]
    report=dict(result='running',mode='native' if args.disk else 'pinned-original',
                scope='Unchanged Logic document binary payloads and sprite/insert references; not compiler include or graphics rendering qualification')
    if args.disk:
        inputs += [args.disk.resolve()]+[ROOT/n for n in ('tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/i386-kernel-input.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC')]
    else:
        inputs += [ROOT/n for n in ('tools/test-i386-timeclock-reference.py','tools/build-iso.py','tools/guest-run.py')]
        reference=runpy.run_path(str(inputs[-3]))
        overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=reference['restore_reference'](overlay)
    report['input_sha256']={str(p):sha(p) for p in inputs}
    try:
        if args.disk:
            fixture_bytes=fixture.read_bytes()
            source_bytes=subprocess.check_output(['git','show','ce055f205fc38536443289fb1cfc73632f6624f4:Apps/Logic/Logic.HC'],cwd=ROOT)
            if sha(ROOT/'Apps/Logic/Logic.HC')!=hashlib.sha256(source_bytes).hexdigest():raise ValueError('Logic source differs from pinned reference')
            disk=out/'working.img'
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={'/LogicDoc.HC':fixture_bytes,'/Apps/Logic/Logic.HC':source_bytes})
            commands=['#include "C:/LogicDoc.HC"',"if(LogicDocumentContract(\"C:/Apps/Logic/Logic.HC\")!=31)throw('RawBlk',TRUE);",'6*7;']
            runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](disk,out/'guest',commands,args.ram_mib,True)
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,{'/LogicDoc.HC','/Apps/Logic/Logic.HC'})
            if files['/LogicDoc.HC']!=fixture_bytes or files['/Apps/Logic/Logic.HC']!=source_bytes:raise ValueError('Delivered source or fixture changed')
        else:
            source=fixture.read_bytes()+b'\nU0 FQReport(U8*s){while(*s)OutU8(0xE9,*s++);}\n'
            source+=b'I64 fq_result=LogicDocumentContract("T:/Apps/Logic/Logic.HC");U8 *fq_line=MStrPrint("LOGIC DOC MASK %d\\n",fq_result);FQReport(fq_line);Free(fq_line);FQReport("DONE Logic document\\n");\n'
            (overlay/'Once.HC').write_bytes(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if 'LOGIC DOC MASK 31\n' not in (out/'guest/debug.log').read_text():raise ValueError('Logic document contract failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==d for p,d in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
