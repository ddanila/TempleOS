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
DEFINITIONS=[
    'class CFindEntry{CFindEntry *next,*parent,*sub;U8 *full_name;I64 user_data,user_data2;U0 start;U16 attr;U8 name[38];I64 clus,size,datetime;};',
    'Bool FindMeta(U8 *name,I64 attr,I64 size){CFindEntry de;Bool ok=FileFind(name,&de)&&de.attr==attr&&de.size==size&&de.clus>0&&de.datetime==0x1122334455667788&&de.full_name;Free(de.full_name);return ok;}',
    'Bool FindName(U8 *name){CFindEntry de;Bool ok=FileFind(name,&de)&&de.full_name&&!StrCmp(de.full_name,name)&&MHeapCtrl(de.full_name)==Fs->data_heap;Free(de.full_name);return ok;}',
    'Bool FindMissing(){CFindEntry de;I64 i;U8 *p=&de;MemSet(p,255,sizeof(de));if(FileFind("C:/Probe/NoFindFile.BIN",&de))return FALSE;for(i=0;i<sizeof(de);i++)if(p[i])return FALSE;return TRUE;}',
    'Bool FindBadFlags(){Bool ok=FALSE;try{FileFind("C:/Probe/FindRaw.BIN",0,1);}catch{ok=Fs->except_ch==\'FUF\';Fs->catch_except=TRUE;}return ok;}'
]
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
        '!FileFind("C:/Probe/NoFindFile.BIN")', '!FileFind(0)',
        '!FileFind("C:/Probe/*.BIN")',
        'FindMeta("C:/Probe/FindRaw.BIN",0x800,3)',
        'FindName("C:/Probe/FindRaw.BIN")', 'FindMissing', 'FindBadFlags']


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--public-entry',action='store_true',help='Require the public CDirEntry type instead of a modeled record')
    parser.add_argument('--public-flags',action='store_true',help='Require original named FUF constants')
    parser.add_argument('--edge-cases',action='store_true',help='Require original early-rejection output preservation and filter boundaries')
    parser.add_argument('--heap-cycles',type=int,default=0,help='Port-only repeated public/private allocation recovery (1..50)')
    args=parser.parse_args()
    if args.heap_cycles<0 or args.heap_cycles>50 or args.heap_cycles and not args.public_entry:
        parser.error('--heap-cycles requires --public-entry and a count from 1 to 50')
    definitions=list(DEFINITIONS)
    if args.public_entry:
        definitions=[s.replace('CFindEntry','CDirEntry') for s in definitions[1:]]
    checks=list(CHECKS)
    if args.edge_cases:
        record='CFindEntry'
        if args.public_entry:record='CDirEntry'
        definitions.append('Bool FindUntouched(U8 *name){'+record+' de;I64 i;U8 *p=&de;MemSet(p,90,sizeof(de));if(FileFind(name,&de))return FALSE;for(i=0;i<sizeof(de);i++)if(p[i]!=90)return FALSE;return TRUE;}')
        checks += ['FindUntouched(0)','FindUntouched("Z:/NoFindDrive.BIN")',
                   '!FileFind("C:/Probe/FindRaw.BIN",0,0xC00)',
                   '!FileFind("C:/Probe/FindChild",0,0xC00)',
                   '!FileFind("C:/Probe/NoFindDir/FindRaw.BIN",0,0x100000)']
    if args.public_flags:
        for value,name in [('0x140000','FUF_SCAN_PARENTS|FUF_Z_OR_NOT_Z'),('0x100000','FUF_SCAN_PARENTS'),('0x40000','FUF_Z_OR_NOT_Z'),('0x800','FUF_JUST_FILES'),('0x400','FUF_JUST_DIRS')]:
            checks=[source.replace(value,name) if 'FileFind(' in source else source for source in checks]
    out=args.out.resolve();out.mkdir(parents=True,exist_ok=True)
    candidate=out/'candidate.img'
    if candidate==args.disk.resolve():parser.error('output overlaps source')
    original=args.disk.read_bytes();candidate.write_bytes(original)
    (out/'result.json').unlink(missing_ok=True)
    report=dict(result='fail',source_disk_sha256=hashlib.sha256(original).hexdigest(),
                scope='Public Bool FileFind existence/filter/alternate/parent/null behavior; metadata/full_name ownership/failure zeroing/invalid flags; modeled record, not public CDirEntry declaration parity')
    if args.public_entry:
        report['scope']=report['scope'].replace('modeled record, not public CDirEntry declaration parity','actual public CDirEntry')
    try:
        overlay=out/'overlay';overlay.mkdir(exist_ok=True)
        lines=['U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}']+[s.replace('C:/Probe/','B:/') for s in definitions]+['U0 OriginalFind(){']
        for index,source in enumerate(SETUP+checks):
            source=source.replace('C:/Probe/','B:/')
            lines.append(f'if(!({source})){{Report("FAIL original FileFind case {index}\\n");return;}}')
        lines+=['Report("DONE original FileFind\\n");}','OriginalFind;']
        (overlay/'Once.HC').write_text('\n'.join(lines)+'\n')
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'oracle.iso')],cwd=ROOT,check=True)
        subprocess.run(['python3','tools/guest-run.py',str(out/'oracle.iso'),'--out',str(out/'oracle'),'--timeout','180','--qmp-stdio'],cwd=ROOT,check=True)
        report['original_oracle']='pass'
        commands=[(source+';',['1']) for source in SETUP]+[(source,[]) for source in definitions]+[(source+';',['1']) for source in checks]
        if args.heap_cycles:
            commands += [('Bool FindRound(){return FindName("C:/Probe/FindRaw.BIN")&&FindMissing()&&FindBadFlags()&&FileFind("C:/Probe/FindChild/FindPacked.BIN",0,0x140000)&&!FileFind("C:/Probe/FindChild",0,0x800);}',[]),
                         ('Bool FindRecovery(I64 cycles){I64 i,used=Fs->data_heap->used_u8s;for(i=0;i<cycles;i++)if(!FindRound())return FALSE;return used==Fs->data_heap->used_u8s;}',[]),
                         ('FindRound;',['1']),(f'FindRecovery({args.heap_cycles});',['1'])]
            if args.edge_cases:
                commands[-4]=(commands[-4][0].replace(';}', '&&FindUntouched(\"Z:/NoFindDrive.BIN\");}'),[])
        commands.append(('6*7;',['42']))
        runner=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        if args.heap_cycles:
            observer=runpy.run_path(str(ROOT/'tools/i386-file-find-heap-observer.py'))['observed_input']
            runner=observer(candidate,report)
        report['behavior']=runner(candidate,out/'behavior',snapshot=False,cpu='486,-fpu',qmp_stdio=True,
            startup_check={'status':'ok','answers':[],'commands':commands})
        verify=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['verify_mutated_volume']
        report['filesystem']=verify(candidate)
        report.update(result='pass',public_directory_entry=args.public_entry,public_flags=args.public_flags,heap_recovery_cycles=args.heap_cycles,edge_cases=args.edge_cases)
    except Exception as error:
        report['error']=str(error);raise
    finally:
        report['source_disk_unchanged']=args.disk.read_bytes()==original
        if not report['source_disk_unchanged']:report.update(result='fail',error='Source changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
