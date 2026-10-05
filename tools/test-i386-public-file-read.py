#!/usr/bin/env python3
"""Original-oracle public FileRead binary/expanded/ownership/failure contract."""
import argparse
import hashlib
import json
import re
from pathlib import Path
import runpy
import struct
import subprocess

ROOT=Path(__file__).resolve().parents[1]
DEFINITIONS=[
    'U8 ReadBytes[4]={65,0,66,255},ReadPackedBytes[64];',
    'U0 ReadSeed(){I64 i;for(i=0;i<64;i++)ReadPackedBytes[i]=65;ReadPackedBytes[1]=0;ReadPackedBytes[2]=255;}',
    'Bool ReadCheck(U8 *name,I64 want){I64 n=-1,a=-1;U8 *p=FileRead(name,&n,&a);Bool ok=p&&n==4&&a==want&&p[0]==65&&p[1]==0&&p[2]==66&&p[3]==255&&p[4]==0;Free(p);return ok;}',
    'Bool ReadPacked(U8 *name){I64 n=-1,a=-1;U8 *p=FileRead(name,&n,&a);Bool ok=p&&n==64&&a==0xC00&&p[0]==65&&p[1]==0&&p[2]==255&&p[63]==65&&p[64]==0;Free(p);return ok;}',
    'Bool ReadOwned(U8 *name){U8 *p=FileRead(name),*q=FileRead(name);Bool ok=p&&q&&p!=q&&MHeapCtrl(p)==Fs->data_heap&&MHeapCtrl(q)==Fs->data_heap;if(ok){p[0]=90;ok=q[0]==65;}Free(p);Free(q);return ok;}',
    'Bool ReadRecovery(U8 *name){I64 i,used=Fs->data_heap->used_u8s;U8 *p;for(i=0;i<20;i++){p=FileRead(name);if(!p)return FALSE;Free(p);}return Fs->data_heap->used_u8s==used;}',
    'Bool ReadEmpty(U8 *name){I64 n=-1,a=-1;U8 *p=FileRead(name,&n,&a);Bool ok=p&&n==0&&a==0x800&&p[0]==0;Free(p);return ok;}',
    'Bool ReadMissing(U8 *name){I64 n=-1,a=-1;U8 *p=FileRead(name,&n,&a);Bool ok=!p&&n==0&&a==0;Free(p);return ok;}'
]
CHECKS=[
    'FileWrite("C:/Probe/ReadRaw.BIN",ReadBytes,4,0x1122334455667788)>0',
    'FileWrite("C:/Probe/ReadPacked.BIN.Z",ReadPackedBytes,64,0x1122334455667788)>0',
    'FileWrite("C:/Probe/ReadEmpty.BIN",0,0,0x1122334455667788)==-1',
    'ReadCheck("C:/Probe/ReadRaw.BIN",0x800)',
    'ReadPacked("C:/Probe/ReadPacked.BIN.Z")',
    'ReadPacked("C:/Probe/ReadPacked.BIN")',
    'ReadOwned("C:/Probe/ReadRaw.BIN")',
    'ReadOwned("C:/Probe/ReadPacked.BIN.Z")',
    'ReadCheck("C:/Probe/ReadRaw.BIN",0x800)',
    'ReadPacked("C:/Probe/ReadPacked.BIN.Z")',
    'ReadEmpty("C:/Probe/ReadEmpty.BIN")',
    'ReadMissing("C:/Probe/NoReadFile.BIN")',
    'ReadRecovery("C:/Probe/ReadRaw.BIN")',
    'ReadRecovery("C:/Probe/ReadPacked.BIN.Z")'
]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--builder',type=Path,default=ROOT/'tools/build-i386-kernel.py',
                        help='Independent image auditor matching the candidate file ABI')
    parser.add_argument('--parents',action='store_true',help='Require original parent search for absolute child paths')
    parser.add_argument('--resident',action='store_true',help='Require resident writes, owned cached reads and replacement back to ordinary storage')
    parser.add_argument('--resident-recovery',action='store_true',help='Twenty port-only resident cache create/remove cycles with public/private heap recovery')
    args=parser.parse_args()
    if args.resident_recovery and not args.resident:
        parser.error('--resident-recovery requires --resident')
    checks=list(CHECKS)
    definitions=list(DEFINITIONS)
    if args.parents:
        checks[3:3]=['DirMk("C:/Probe/ReadChild")',
                     'ReadCheck("C:/Probe/ReadChild/ReadRaw.BIN",0x800)',
                     'ReadPacked("C:/Probe/ReadChild/ReadPacked.BIN")']
    if args.resident:
        definitions += [
            'Bool ResidentWrite(U8 *name,I64 byte,I64 attr){I64 c;ReadBytes[0]=byte;c=FileWrite(name,ReadBytes,4,0x1122334455667788,attr);ReadBytes[0]=65;return c>0;}',
            'Bool ResidentRead(U8 *name,I64 byte,I64 attr){I64 n=-1,a=-1;U8 *p=FileRead(name,&n,&a);Bool ok=p&&n==4&&a==attr&&p[0]==byte&&p[1]==0&&p[2]==66&&p[3]==255&&p[4]==0;Free(p);return ok;}']
        checks[-2:-2]=[
            'FileWrite("C:/Probe/ReadResident.BIN",ReadBytes,4,0x1122334455667788,0x200)>0',
            'ReadCheck("C:/Probe/ReadResident.BIN",0)',
            'ReadOwned("C:/Probe/ReadResident.BIN")',
            'ResidentWrite("C:/Probe/ReadResident.BIN",90,0x200)',
            'ResidentRead("C:/Probe/ReadResident.BIN",90,0)',
            'ResidentWrite("C:/Probe/ReadResident.BIN",67,0)',
            'ResidentRead("C:/Probe/ReadResident.BIN",67,0x800)']
    out=args.out.resolve();out.mkdir(parents=True,exist_ok=True)
    candidate=out/'candidate.img'
    if candidate==args.disk.resolve():parser.error('output overlaps source')
    original=args.disk.read_bytes();candidate.write_bytes(original)
    (out/'result.json').unlink(missing_ok=True)
    report=dict(result='fail',source_disk_sha256=hashlib.sha256(original).hexdigest(),
                scope='Public three-argument FileRead: binary/expanded/alternate .Z, size/attributes, terminator, independent allocations, empty and missing; not parent/resident/FileFind parity')
    report.update(parent_search=args.parents,resident=args.resident)
    exclusions=['FileFind parity']
    if not args.parents:exclusions.insert(0,'parent search')
    if not args.resident:exclusions.insert(0,'resident cache')
    report['scope']=report['scope'].split('; not ')[0]+'; excludes '+', '.join(exclusions)
    if args.resident:
        report['scope']+='; additionally resident write-populated cache ownership, changed-byte replacement and removal of residence'
    try:
        overlay=out/'overlay';overlay.mkdir(exist_ok=True)
        lines=['U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}']+definitions
        lines.append('U0 OriginalReads(){CArcCompress *arc;U8 *line;ReadSeed;')
        for index,check in enumerate(checks[:-2]):
            check=check.replace('C:/Probe/','B:/')
            lines.append(f'if(!({check})){{Report("FAIL original FileRead case {index}\\n");return;}}')
        lines+=['arc=CompressBuf(ReadPackedBytes,64);line=MStrPrint("EXPORT ReadPacked.arc %X %X\\n",arc,arc->compressed_size);Report(line);Free(line);',
                'Report("DONE original FileRead\\n");}','OriginalReads;']
        (overlay/'Once.HC').write_text('\n'.join(lines)+'\n')
        subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(out/'oracle.iso')],cwd=ROOT,check=True)
        subprocess.run(['python3','tools/guest-run.py',str(out/'oracle.iso'),'--out',str(out/'oracle'),'--timeout','180','--qmp-stdio'],cwd=ROOT,check=True)
        report['original_oracle']='pass'
        report['heap_recovery_scope']='Port-only exact current-task accounting across twenty read/free cycles; excluded from original functional oracle'
        #Write setup first so an undefined FileRead is a qualified API failure.
        commands=[(DEFINITIONS[0],[]),(DEFINITIONS[1],[]),('ReadSeed;',[])]+[(check+';',['1']) for check in checks[:3]]
        commands += [(source,[]) for source in definitions[2:]]
        commands += [(check+';',['1']) for check in checks[3:]]
        if args.resident_recovery:
            commands += [('U8 *ResidentName="C:/Probe/ReadResident.BIN";',[]),
                         ('Bool ResidentRound(){return ResidentWrite(ResidentName,90,0x200)&&ResidentRead(ResidentName,90,0)&&ResidentWrite(ResidentName,67,0)&&ResidentRead(ResidentName,67,0x800);}',[]),
                         ('U0 ResidentHeapText(U8 *s){while(*s)OutU8(0xE9,*s++);}',[]),
                         ('U0 ResidentHeapHex(I64 n){U8 *d="0123456789ABCDEF";I64 i;for(i=60;i>=0;i-=4)OutU8(0xE9,d[(n>>i)&15]);OutU8(0xE9,10);}',[]),
                         ('U0 ResidentJobs(){CJob *h=&Fs->srv_ctrl.next_waiting,*j=h->next;ResidentHeapText("RESIDENT JOBS\\n");while(j!=h){ResidentHeapHex(j->job_code);ResidentHeapHex(j->msg_code);ResidentHeapHex(MSize2(j));j=j->next;}}',[]),
                         ('Bool ResidentQuiet(){CJob *h=&Fs->srv_ctrl.next_waiting,*j=h->next;while(j!=h){if(j->job_code!=JOBT_MSG||j->msg_code!=MSG_KEY_UP||MHeapCtrl(j)!=Fs->gs->seth_task->data_heap)return FALSE;j=j->next;}FlushMsgs;return h->next==h;}',[]),
                         ('U0 ResidentBefore(I64 u,I64 r){ResidentHeapText("RESIDENT BEFORE\\n");ResidentHeapHex(u);ResidentHeapHex(r);}',[]),
                         ('Bool ResidentCounts(I64 u,I64 v,I64 r,I64 s){ResidentHeapText("RESIDENT HEAPS\\n");ResidentHeapHex(u);ResidentHeapHex(v);ResidentHeapHex(r);ResidentHeapHex(s);return u==v&&r==s;}',[]),
                         ('I64 ResidentRootUsed(){return Fs->gs->seth_task->data_heap->used_u8s;}',[]),
                         ('Bool ResidentHeaps(I64 u,I64 r){I64 v,s;ResidentJobs;if(!ResidentQuiet)return FALSE;v=Fs->data_heap->used_u8s;s=ResidentRootUsed;return ResidentCounts(u,v,r,s);}',[]),
                         ('Bool FindRecovery(){I64 i,u,r;if(!ResidentQuiet)return FALSE;u=Fs->data_heap->used_u8s;r=ResidentRootUsed;ResidentBefore(u,r);for(i=0;i<20;i++)if(!ResidentRound)return FALSE;return ResidentHeaps(u,r);}',[]),
                         ('FindRecovery;',['1'])]
        commands += [('6*7;',['42'])]
        if args.resident_recovery:
            report['resident_heap_recovery_scope'] = 'Only validated root-owned key-up jobs are quiesced before snapshots; twenty create/update/remove cycles: exact caller and persistent public root task heap used bytes, plus independent private heap snapshots'
            #The read-only observer recognizes FindRecovery as its sampling boundary.
            commands[-2]=('FindRecovery();',['1'])
            runner=runpy.run_path(str(ROOT/'tools/i386-file-find-heap-observer.py'))['observed_input'](candidate,report)
        else:
            runner=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input']
        report['behavior']=runner(candidate,out/'behavior',snapshot=False,cpu='486,-fpu',qmp_stdio=True,
            startup_check={'status':'ok','answers':[],'commands':commands})
        build=runpy.run_path(str(args.builder.resolve()))
        report['filesystem']=build['verify_mutated_volume'](candidate)
        paths={'/Probe/ReadRaw.BIN','/Probe/ReadPacked.BIN.Z','/Probe/ReadEmpty.BIN'}
        if args.resident:paths.add('/Probe/ReadResident.BIN')
        files=build['mutated_file_contents'](candidate,paths)
        if files.get('/Probe/ReadRaw.BIN')!=b'A\0B\xff' or files.get('/Probe/ReadEmpty.BIN')!=b'':
            raise ValueError('Public reads changed persisted bytes')
        if args.resident and files.get('/Probe/ReadResident.BIN')!=b'C\0B\xff':
            raise ValueError('Removing residence did not persist replacement bytes')
        archive=files.get('/Probe/ReadPacked.BIN.Z')
        if archive!=(out/'oracle/ReadPacked.arc').read_bytes():
            raise ValueError('Public reads changed persisted compressed bytes')
        stored,expanded,kind=struct.unpack_from('<qqB',archive)
        if kind!=3 or expanded!=64 or stored>=81:
            raise ValueError('Compressed read fixture did not exercise eight-bit expansion')
        report.update(result='pass',parent_search=args.parents,resident=args.resident,
                      resident_recovery_cycles=20 if args.resident_recovery else 0)
    except Exception as error:
        report['error']=str(error);raise
    finally:
        trace=out/'behavior/debug.log'
        if args.resident_recovery and trace.exists():
            match=re.search(r'RESIDENT HEAPS\n'+r'([0-9A-F]{16})\n'*4,trace.read_text(errors='replace'))
            if match:
                values=[int(value,16) for value in match.groups()]
                report['resident_public_heap_observation']=dict(zip(('caller_before','caller_after','root_before','root_after'),values))
                report['resident_public_heap_observation']['result']='pass' if values[0]==values[1] and values[2]==values[3] else 'fail'
            initial=re.search(r'RESIDENT BEFORE\n'+r'([0-9A-F]{16})\n'*2,trace.read_text(errors='replace'))
            if initial:
                report['resident_public_heap_initial']={'caller':int(initial[1],16),'root':int(initial[2],16)}
        report['source_disk_unchanged']=args.disk.read_bytes()==original
        if not report['source_disk_unchanged']:report.update(result='fail',error='Source changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
