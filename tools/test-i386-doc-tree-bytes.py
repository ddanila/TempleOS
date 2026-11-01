#!/usr/bin/env python3
"""Compare serialized document trees with the pinned original."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/'tests/guest/i386-doc-tree-bytes/Contract.HC'
NAMES=[f'tree-bytes{i}.DD' for i in range(3)]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?')
    parser.add_argument('--reference',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--ram-mib',type=int,choices=(8,64),default=64)
    args=parser.parse_args()
    if bool(args.disk)!=bool(args.reference):parser.error('Native run requires --reference')
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[Path(__file__).resolve(),FIXTURE,ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',ROOT/'tools/test-i386-timeclock-reference.py']
    pins={str(p):sha(p) for p in inputs}
    report=dict(result='running',mode='native' if args.disk else 'pinned-original',scope='Exact DocSave bytes after tree create, nested append/sibling, and branch rewrite')
    try:
        if not args.disk:
            overlay=out/'overlay';overlay.mkdir()
            helper=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
            report['system_source_sha256']=helper['restore_reference'](overlay)
            (overlay/'DocTreeBytes.HC').write_bytes(FIXTURE.read_bytes())
            once='U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}\n#include "::/DocTreeBytes.HC"\n'
            once+='I64 m=TGB(\'B\'),i,size;U8 *name,*buf,*line;if(m!=7)throw(\'TreeByte\');\n'
            once+='for(i=0;i<3;i++){name=MStrPrint("B:/tree-bytes%d.DD",i);buf=FileRead(name,&size);line=MStrPrint("EXPORT tree-bytes%d.DD %X %X\\n",i,buf,size);Report(line);Free(line);Free(name);}\nReport("DONE doc tree bytes\\n");\n'
            (overlay/'Once.HC').write_text(once)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            observed={n:(out/'guest'/n).read_bytes() for n in NAMES}
        else:
            reference=args.reference.resolve();baseline=json.loads((reference/'result.json').read_text())
            if baseline.get('result')!='pass' or baseline.get('mode')!='pinned-original':raise ValueError('Need passing original reference')
            expected={n:(reference/'guest'/n).read_bytes() for n in NAMES}
            if any(hashlib.sha256(v).hexdigest()!=baseline['capture_sha256'][n] for n,v in expected.items()):raise ValueError('Original capture changed')
            source=args.disk.resolve();inputs += [source,reference/'result.json']+[reference/'guest'/n for n in NAMES]
            inputs += [ROOT/n for n in ('tools/i386-kernel-input.py','tools/package-i386-native-image.py','tools/build-i386-kernel.py','Kernel/FontStd.HC')]
            pins.update({str(p):sha(p) for p in inputs if str(p) not in pins})
            working=out/'working.img'
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](source,working,additions={'/DocTreeBytes.HC':FIXTURE.read_bytes()})
            commands=[('#include "/Kernel/I386/PublicUser.HH"',[]),('#include "C:/DocTreeBytes.HC"',[]),('TGB(67);',['7']),('6*7;',['42'])]
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](working,out/'guest',snapshot=False,ram_mib=args.ram_mib,cpu='486,-fpu',accel='tcg',qmp_stdio=True,welcome=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False,'command_timeout':120})
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](working,{'/DocTreeBytes.HC'}|{'/'+n for n in NAMES})
            if files.get('/DocTreeBytes.HC')!=FIXTURE.read_bytes():raise ValueError('Delivered fixture changed')
            observed={n:files['/'+n] for n in NAMES}
            if observed!=expected:raise ValueError('Serialized tree bytes differ from original')
        report['capture_sha256']={n:hashlib.sha256(data).hexdigest() for n,data in observed.items()}
        report['result']='pass'
    except Exception as error:
        report.update(result='fail',error=str(error));raise
    finally:
        report['input_sha256']=pins
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
