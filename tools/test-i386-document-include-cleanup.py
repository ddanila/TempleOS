#!/usr/bin/env python3
"""Check repeated document includes and compiler-error recovery."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import struct
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path,nargs='?')
    ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-document-include-cleanup/Contract.HC'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    binary=struct.pack('<IIII',1,0,4,1)+bytes([0,65,0,255])
    files={'/DocIncludeCase/Size.HC':b'$IS,"payload",BI=1$;\n\0'+binary,
           '/DocIncludeCase/Bad.HC':b'$IS,"payload",BI=1$;\nI64 broken=;\n\0'+binary,
           '/DocIncludeCase/Cleanup.HC':fixture.read_bytes()}
    inputs=[Path(__file__).resolve(),fixture]
    report=dict(result='running',mode='native' if args.disk else 'pinned-original',scope='Repeated real document includes and task heap recovery on original/native; native also checks compiler-error unwind and later command; not cancellation, OOM, task death or AOT qualification')
    if args.disk:
        inputs += [args.disk.resolve()]+[ROOT/n for n in ('tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/i386-kernel-input.py','tools/test-i386-timeclock-welcome.py','Kernel/FontStd.HC')]
    else:
        inputs += [ROOT/n for n in ('tools/test-i386-timeclock-reference.py','tools/build-iso.py','tools/guest-run.py')]
        reference=runpy.run_path(str(inputs[-3]));overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=reference['restore_reference'](overlay)
    report['input_sha256']={str(p):sha(p) for p in inputs}
    try:
        if args.disk:
            disk=out/'working.img'
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions=files)
            commands=['#include "C:/DocIncludeCase/Cleanup.HC"',"if(DocumentIncludeCleanup('C')!=31)throw('DocInc',TRUE);",'6*7;']
            runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](disk,out/'guest',commands,64,True,allow_inner_rejection=True)
            delivered=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,set(files))
            if delivered!=files:raise ValueError('Delivered include files changed')
        else:
            for name,data in files.items():
                path=overlay/name.lstrip('/');path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+b'\nU0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}\nI64 result=DocumentIncludeCleanup(\'T\',FALSE);U8 *line=MStrPrint(\"DOCUMENT CLEANUP MASK %d\\n\",result);Report(line);Free(line);Report(\"DONE document cleanup\\n\");\n')
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if 'DOCUMENT CLEANUP MASK 7\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original cleanup contract failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==d for p,d in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
