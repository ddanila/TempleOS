#!/usr/bin/env python3
"""Original-oracle FileFind existence, file/directory filters and lookup flags."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess

ROOT=Path(__file__).resolve().parents[1]
SETUP=['DirMk("C:/Probe/FindChild")',
       'FileWrite("C:/Probe/FindRaw.BIN","ABC",3,0x1122334455667788)>0',
       'FileWrite("C:/Probe/FindPacked.BIN.Z","AAABBBCCC",9,0x1122334455667788)>0']
CHECKS=['FileFind("C:/Probe/FindRaw.BIN")',
        'FileFind("C:/Probe/FindRaw.BIN",0,0x800)',
        '!FileFind("C:/Probe/FindRaw.BIN",0,0x400)',
        'FileFind("C:/Probe/FindChild",0,0x400)',
        '!FileFind("C:/Probe/FindChild",0,0x800)',
        '!FileFind("C:/Probe/FindRaw.BIN.Z")',
        '!FileFind("C:/Probe/FindPacked.BIN")',
        'FileFind("C:/Probe/FindPacked.BIN",0,0x40000)',
        '!FileFind("C:/Probe/FindChild/FindRaw.BIN")',
        'FileFind("C:/Probe/FindChild/FindRaw.BIN",0,0x100000)',
        'FileFind("C:/Probe/FindChild/FindPacked.BIN",0,0x140000)',
        '!FileFind("C:/Probe/NoFindFile.BIN")', '!FileFind(0)']


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    out=args.out.resolve();out.mkdir(parents=True,exist_ok=True)
    candidate=out/'candidate.img'
    if candidate==args.disk.resolve():parser.error('output overlaps source')
    original=args.disk.read_bytes();candidate.write_bytes(original)
    (out/'result.json').unlink(missing_ok=True)
    report=dict(result='fail',source_disk_sha256=hashlib.sha256(original).hexdigest(),
                scope='Public Bool FileFind existence/filter/alternate/parent/null behavior; not CDirEntry metadata/full_name ownership/wildcard/invalid-flag parity')
    try:
        overlay=out/'overlay';overlay.mkdir(exist_ok=True)
        lines=['U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}','U0 OriginalFind(){']
        for index,source in enumerate(SETUP+CHECKS):
            source=source.replace('C:/Probe/','B:/')
            lines.append(f'if(!({source})){{Report("FAIL original FileFind case {index}\\n");return;}}')
        lines+=['Report("DONE original FileFind\\n");}','OriginalFind;']
        (overlay/'Once.HC').write_text('\n'.join(lines)+'\n')
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'oracle.iso')],cwd=ROOT,check=True)
        subprocess.run(['python3','tools/guest-run.py',str(out/'oracle.iso'),'--out',str(out/'oracle'),'--timeout','180','--qmp-stdio'],cwd=ROOT,check=True)
        report['original_oracle']='pass'
        commands=[(source+';',['1']) for source in SETUP+CHECKS]+[('6*7;',['42'])]
        runner=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior']=runner(candidate,out/'behavior',snapshot=False,cpu='486,-fpu',qmp_stdio=True,
            startup_check={'status':'ok','answers':[],'commands':commands})
        verify=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume']
        report['filesystem']=verify(candidate)
        report['result']='pass'
    except Exception as error:
        report['error']=str(error);raise
    finally:
        report['source_disk_unchanged']=args.disk.read_bytes()==original
        if not report['source_disk_unchanged']:report.update(result='fail',error='Source changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
