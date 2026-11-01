#!/usr/bin/env python3
"""Compare FAT long-name entry decoding on original and native."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/'tests/guest/i386-fat-long-name/Contract.HC'

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
    inputs=[Path(__file__).resolve(),FIXTURE,ROOT/'Kernel/BlkDev/FATLongNameCore.HC']
    report=dict(result='running',mode='native' if args.disk else 'shared-original' if args.shared else 'pinned-original-source',
                scope='Original source body on pinned original, or native binding: up to three long-name slots, checksum, invalid metadata, low-byte Unicode and state reset; not full FAT traversal')
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
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={'/FatLongName.HC':FIXTURE.read_bytes()})
            commands=[('#include "C:/FatLongName.HC"',[]),('FLContract;',['895']),('6*7;',['42'])]
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](disk,out/'guest',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='tcg',qmp_stdio=True,welcome=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False,'command_timeout':120,'rejection_prefixes':('INPUT REJECT ','WINMGR window exception ')})
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,{'/FatLongName.HC'})
            if files['/FatLongName.HC']!=FIXTURE.read_bytes():raise ValueError('Delivered fixture changed')
        else:
            if args.shared:
                original=(ROOT/'Kernel/BlkDev/FATLongNameCore.HC').read_text()
                expected_mask=895
            else:
                pinned=subprocess.check_output(['git','show',ref['REFERENCE']+':Kernel/BlkDev/FileSysFAT.HC'],cwd=ROOT).decode()
                start=pinned.index('U8 fat_long_name_map[')
                end=pinned.index('Bool FAT32CDirFill(',start)
                original=pinned[start:end]
                report['pinned_body_sha256']=hashlib.sha256(original.encode()).hexdigest()
                expected_mask=255
            declaration='class FLLong {U8 ord;U16 name1[5];U8 attr,type,xsum;U16 name2[6],zero,name3[2];};\n'
            body=(declaration+original.replace('CFAT32DirEntryLong','FLLong').replace('DirLongNameFill','FLOriginalDecode').replace('fat_long_name_map','fl_original_map')).encode()
            source=body+FIXTURE.read_bytes().replace(b'DirLongNameFill',b'FLOriginalDecode')+b'\nU0 FLReport(U8*s){while(*s)OutU8(0xE9,*s++);}\n'
            source+=b'I64 fl_mask=FLContract;U8 *fl_line=MStrPrint("FAT LONG MASK %d\\n",fl_mask);FLReport(fl_line);Free(fl_line);FLReport("DONE fat long\\n");\n'
            (overlay/'Once.HC').write_bytes(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if f'FAT LONG MASK {expected_mask}\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original FAT long-name contract failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
