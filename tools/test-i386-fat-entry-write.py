#!/usr/bin/env python3
"""Compare FAT directory entry construction on original and native."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/'tests/guest/i386-fat-entry-write/Contract.HC'

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?')
    parser.add_argument('--shared',action='store_true',help='Run the current shared writer and decoder on original')
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if args.disk and args.shared:parser.error('Choose native or shared-original')
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[Path(__file__).resolve(),FIXTURE]+[ROOT/'Kernel/BlkDev'/n for n in ('FileSysFAT.HC','FATDateToDosCore.HC','FATNameCore.HC','FATLongNameCore.HC','FATDirFillCore.HC')]
    report=dict(result='running',mode='native' if args.disk else 'shared-original' if args.shared else 'pinned-original-source',
                scope='Original source body on pinned original, or native binding: entry construction and decoding with output canaries; not disk mutation or full FAT traversal')
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
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={'/FatEntryWrite.HC':FIXTURE.read_bytes()})
            commands=[('#include "C:/FatEntryWrite.HC"',[]),('FWContract(TRUE);',['31']),('6*7;',['42'])]
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](disk,out/'guest',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='tcg',qmp_stdio=True,welcome=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False,'command_timeout':120,'rejection_prefixes':('INPUT REJECT ','WINMGR window exception ')})
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,{'/FatEntryWrite.HC'})
            if files['/FatEntryWrite.HC']!=FIXTURE.read_bytes():raise ValueError('Delivered fixture changed')
        else:
            if args.shared:
                original=''.join((ROOT/'Kernel/BlkDev'/n).read_text() for n in ('FATDateToDosCore.HC','FATNameCore.HC','FATLongNameCore.HC','FATDirFillCore.HC'))
                expected_mask=31
            else:
                pinned=subprocess.check_output(['git','show',ref['REFERENCE']+':Kernel/BlkDev/FileSysFAT.HC'],cwd=ROOT).decode()
                date=pinned[:pinned.index('CDate Dos2CDate(')]
                name_start=pinned.index('Bool FATNameTo(');name_end=pinned.index('U8 fat_long_name_map[',name_start)
                core_start=pinned.index('U8 fat_long_name_map[');core_end=pinned.index('Bool FAT32CDirFill(',core_start)
                writer_start=pinned.index('Bool FAT32DirFill(',core_end);writer_end=pinned.index('Bool FAT32FileFind(',writer_start)
                original=date+pinned[name_start:name_end]+pinned[core_start:core_end]+pinned[writer_start:writer_end]
                report['pinned_body_sha256']=hashlib.sha256(original.encode()).hexdigest()
                expected_mask=7
            declaration='class FWEntry {U8 name[11],attr,NTres,CrtTimeTenth;U16 CrtTime,CrtDate,LstAccDate,clus_hi,WrtTime,WrtDate,clus_lo;U32 size;};class FWLong {U8 ord;U16 name1[5];U8 attr,type,xsum;U16 name2[6],zero,name3[2];};\n'
            body=(declaration+original.replace('CFAT32DirEntryLong','FWLong').replace('CFAT32DirEntry','FWEntry').replace('CDate2Dos','FWDateToDos').replace('FATNameTo','FWNameTo').replace('FATNameXSum','FWNameSum').replace('FATFromName','FWFromName').replace('DirLongNameFill','FWDecode').replace('FAT32CDirFill','FWDirRead').replace('Dos2CDate','FWDosToDate').replace('FAT32DirFill','FWWrite').replace('fat_long_name_map','fw_original_map')).encode()
            source=body+FIXTURE.read_bytes().replace(b'FAT32DirFill',b'FWWrite').replace(b'DirLongNameFill',b'FWDecode').replace(b'FATFromName',b'FWFromName').replace(b'FATNameXSum',b'FWNameSum')+b'\nU0 FWReport(U8*s){while(*s)OutU8(0xE9,*s++);}\n'
            source+=f'I64 fw_mask=FWContract({"TRUE" if args.shared else "FALSE"});'.encode()+b'U8 *fw_line=MStrPrint("FAT WRITE MASK %d\\n",fw_mask);FWReport(fw_line);Free(fw_line);FWReport("DONE fat write\\n");\n'
            (overlay/'Once.HC').write_bytes(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if f'FAT WRITE MASK {expected_mask}\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original FAT entry writer contract failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
