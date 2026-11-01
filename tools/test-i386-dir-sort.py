#!/usr/bin/env python3
"""Compare directory tree sorting on original and native."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/'tests/guest/i386-dir-sort/Contract.HC'

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?')
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[Path(__file__).resolve(),FIXTURE,ROOT/'Kernel/BlkDev/DirFilesSortCore.HC']
    report=dict(result='running',mode='native' if args.disk else 'original-source',
                scope='Original source body on pinned original, or native binding: name and cluster sorting of nested siblings, including singleton roots and exact caller heap; not enumeration')
    if args.disk:
        inputs += [args.disk.resolve()]+[ROOT/n for n in ('tools/package-i386-native-image.py','tools/build-i386-kernel.py','tools/i386-kernel-input.py','Kernel/FontStd.HC')]
    else:
        inputs += [ROOT/n for n in ('tools/test-i386-timeclock-reference.py','tools/build-iso.py','tools/guest-run.py')]
        ref=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'));overlay=out/'overlay';overlay.mkdir()
        report['reference_sha256']=ref['restore_reference'](overlay)
    report['input_sha256']={str(p):sha(p) for p in inputs}
    try:
        if args.disk:
            disk=out/'working.img'
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={'/DirSort.HC':FIXTURE.read_bytes()})
            commands=[('#include "C:/DirSort.HC"',[]),('DSContract;',['511']),('6*7;',['42'])]
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](disk,out/'guest',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='tcg',qmp_stdio=True,welcome=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False,'command_timeout':120,'rejection_prefixes':('INPUT REJECT ','WINMGR window exception ')})
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,{'/DirSort.HC'})
            if files['/DirSort.HC']!=FIXTURE.read_bytes():raise ValueError('Delivered fixture changed')
        else:
            original=(ROOT/'Kernel/BlkDev/DirFilesSortCore.HC').read_text()
            body=original.replace('DirFilesSort','DSOriginalSort').encode()
            source=body+FIXTURE.read_bytes().replace(b'DirFilesSort',b'DSOriginalSort')+b'\nU0 DSReport(U8*s){while(*s)OutU8(0xE9,*s++);}\n'
            source+=b'I64 ds_mask=DSContract;U8 *ds_line=MStrPrint("DIR SORT MASK %d\\n",ds_mask);DSReport(ds_line);Free(ds_line);DSReport("DONE dir sort\\n");\n'
            (overlay/'Once.HC').write_bytes(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if 'DIR SORT MASK 511\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original sorting contract failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
