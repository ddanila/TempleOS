#!/usr/bin/env python3
"""Exercise unchanged TimeClock punch commands with emulated keyboard events."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil

ROOT=Path(__file__).resolve().parents[1]
SAVE='U0 PhysicalSave(){I64 n;U8 *p=FileRead(TIME_FILENAME,&n);if(p){FileWrite("C:/physical.DATA",p,n);Free(p);}}'

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args()
    out=args.out.resolve();source=args.disk.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True);image=out/'working.img'
    helper=ROOT/'tools/test-i386-timeclock-welcome.py';build=ROOT/'tools/build-i386-kernel.py';reference=ROOT/'tools/test-i386-timeclock-punch-reference.py';inventory=ROOT/'docs/i386-compatibility-inventory.json'
    paths=[source,Path(__file__).resolve(),helper,build,reference,inventory,ROOT/'Kernel/FontStd.HC']
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,scope='Unchanged TimeClock PunchIn/PunchOut with QEMU keyboard events, multiline descriptions and cold-reboot record recovery; not full VGA or application qualification')
    try:
        read=runpy.run_path(str(build))['mutated_file_contents'];decode=runpy.run_path(str(reference))['decode']
        expected={('/'+e['path']):e['reference_sha256'] for e in json.loads(inventory.read_text())['entries'] if e['path'].startswith('Apps/TimeClock/')}
        files=read(source,set(expected))
        if {n:hashlib.sha256(v).hexdigest() for n,v in files.items()}!=expected:raise ValueError('TimeClock source differs from original')
        shutil.copyfile(source,image)
        guest=runpy.run_path(str(helper))['guest']
        guest(image,out/'first',['#include "C:/Apps/TimeClock/Load.HC"',('PunchIn;','alpha\nbeta\n\x1b'),('PunchOut;','finish\n\x1b'),SAVE,'PhysicalSave;'],64,True)
        first=read(image,{'/physical.DATA'})['/physical.DATA'];records=decode(first)
        if [(kind,desc) for kind,date,desc in records]!=[(1,b'alpha\nbeta\n'),(2,b'finish\n')]:raise ValueError('Punch records differ from original input contract')
        if records[1][1]<records[0][1]:raise ValueError('Punch dates went backwards')
        guest(image,out/'reopen',['#include "C:/Apps/TimeClock/Load.HC"',SAVE,'PhysicalSave;'],64,True)
        if read(image,{'/physical.DATA'})['/physical.DATA']!=first:raise ValueError('Cold-reboot records changed')
        report.update(result='pass',logical_sha256=hashlib.sha256(first).hexdigest(),records=[dict(type=k,date_ticks=d,description=t.decode('latin1')) for k,d,t in records])
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(name))==digest for name,digest in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
