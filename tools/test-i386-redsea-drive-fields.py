#!/usr/bin/env python3
"""Compare mounted RedSea public drive fields with the on-disk header."""
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
    fixture=ROOT/'tests/guest/i386-redsea-drive-fields/Contract.HC'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[Path(__file__).resolve(),fixture]
    report=dict(result='running',mode='native' if args.disk else 'pinned-original',
                scope='RedSea mounted drive metadata against its actual boot sector; not FAT cache allocation, drive initialization or public block I/O qualification')
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
            fixture_bytes=b'public extern Bool I386RawBlocks(CDrv *drive,U8 *buffer,I64 block,I64 count,Bool write);\nBool RBRead(CDrv *d,U8 *b,I64 n,I64 c){return I386RawBlocks(d,b,n,c,FALSE); }\n'+fixture.read_bytes()
            disk=out/'working.img'
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={'/RawBlocks.HC':fixture_bytes})
            commands=['#include "C:/RawBlocks.HC"',"if(RedSeaDriveFields(Fs->cur_dv)!=31)throw('RawBlk',TRUE);",'6*7;']
            runpy.run_path(str(ROOT/'tools/test-i386-timeclock-welcome.py'))['guest'](disk,out/'guest',commands,args.ram_mib,True)
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,{'/RawBlocks.HC'})
            if files['/RawBlocks.HC']!=fixture_bytes:raise ValueError('Delivered fixture changed')
        else:
            source=b'Bool RBRead(CDrv *d,U8 *b,I64 n,I64 c){return BlkRead(d,b,n,c); }\n'+fixture.read_bytes()+b'\nU0 FQReport(U8*s){while(*s)OutU8(0xE9,*s++);}\n'
            source+=b'Cd("B:/");I64 fq_result=RedSeaDriveFields(Fs->cur_dv);U8 *fq_line=MStrPrint("RAW BLOCK MASK %d\\n",fq_result);FQReport(fq_line);Free(fq_line);FQReport("DONE raw blocks\\n");\n'
            (overlay/'Once.HC').write_bytes(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if 'RAW BLOCK MASK 31\n' not in (out/'guest/debug.log').read_text():raise ValueError('Raw blocks contract failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==d for p,d in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
