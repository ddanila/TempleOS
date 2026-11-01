#!/usr/bin/env python3
"""Compare FAT directory metadata decoding on original and native."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/'tests/guest/i386-fat-entry-read/Contract.HC'

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?')
    parser.add_argument('--shared',action='store_true',help='Run the current shared decoder on original')
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if args.disk and args.shared:parser.error('Choose native or shared-original')
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[Path(__file__).resolve(),FIXTURE]+[ROOT/'Kernel/BlkDev'/n for n in ('FileSysFAT.HC','FATNameCore.HC','FATDateFromDosCore.HC','FATDirReadCore.HC')]
    report=dict(result='running',mode='native' if args.disk else 'shared-original' if args.shared else 'pinned-original-source',
                scope='Original source body on pinned original, or native binding: short and retained long names, cluster, size, attributes and DOS timestamps; not FAT traversal')
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
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={'/FatEntryRead.HC':FIXTURE.read_bytes()})
            commands=[('#include "C:/FatEntryRead.HC"',[]),('FRContract;',['63']),('6*7;',['42'])]
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](disk,out/'guest',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='tcg',qmp_stdio=True,welcome=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False,'command_timeout':120,'rejection_prefixes':('INPUT REJECT ','WINMGR window exception ')})
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,{'/FatEntryRead.HC'})
            if files['/FatEntryRead.HC']!=FIXTURE.read_bytes():raise ValueError('Delivered fixture changed')
        else:
            if args.shared:
                names=(ROOT/'Kernel/BlkDev/FATNameCore.HC').read_text()
                original=(ROOT/'Kernel/BlkDev/FATDateFromDosCore.HC').read_text()+names[names.index('Bool FATFromName('):]+(ROOT/'Kernel/BlkDev/FATDirReadCore.HC').read_text()
            else:
                pinned=subprocess.check_output(['git','show',ref['REFERENCE']+':Kernel/BlkDev/FileSysFAT.HC'],cwd=ROOT).decode()
                date_start=pinned.index('CDate Dos2CDate(');date_end=pinned.index('U0 FAT32Init(',date_start)
                name_start=pinned.index('Bool FATFromName(');name_end=pinned.index('U8 fat_long_name_map[',name_start)
                read_start=pinned.index('Bool FAT32CDirFill(');read_end=pinned.index('Bool FAT32DirFill(',read_start)
                original=pinned[date_start:date_end]+pinned[name_start:name_end]+pinned[read_start:read_end]
                report['pinned_body_sha256']=hashlib.sha256(original.encode()).hexdigest()
            expected_mask=63
            declaration='class FREntry {U8 name[11],attr,NTres,CrtTimeTenth;U16 CrtTime,CrtDate,LstAccDate,clus_hi,WrtTime,WrtDate,clus_lo;U32 size;};\n'
            body=(declaration+original.replace('CFAT32DirEntry','FREntry').replace('Dos2CDate','FROriginalDate').replace('FATFromName','FROriginalFrom').replace('FAT32CDirFill','FROriginalRead')).encode()
            source=body+FIXTURE.read_bytes().replace(b'FAT32CDirFill',b'FROriginalRead')+b'\nU0 FRReport(U8*s){while(*s)OutU8(0xE9,*s++);}\n'
            source+=b'I64 fr_mask=FRContract;U8 *fr_line=MStrPrint("FAT READ MASK %d\\n",fr_mask);FRReport(fr_line);Free(fr_line);FRReport("DONE fat read\\n");\n'
            (overlay/'Once.HC').write_bytes(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if f'FAT READ MASK {expected_mask}\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original FAT entry decode contract failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
