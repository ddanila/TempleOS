#!/usr/bin/env python3
"""Compare FAT short-name conversion on original and native."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/'tests/guest/i386-fat-name/Contract.HC'

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('disk',type=Path,nargs='?')
    parser.add_argument('--shared',action='store_true',help='Run the current shared body on the original system')
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if args.disk and args.shared:parser.error('Choose native or shared-original')
    out=args.out.resolve()
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True)
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    inputs=[Path(__file__).resolve(),FIXTURE,ROOT/'Kernel/BlkDev/FATNameCore.HC']
    report=dict(result='running',mode='native' if args.disk else 'shared-original' if args.shared else 'pinned-original-source',
                scope='Original source body on pinned original, or native binding: short-name conversion, dot entries, rejection, checksums and bounded overlong-extension write; original documents inherited overflow; not FAT directory traversal')
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
            report['packaging']=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),disk,additions={'/FatNameContract.HC':FIXTURE.read_bytes()})
            commands=[('#include "C:/FatNameContract.HC"',[]),('FNContract;',['3839']),('6*7;',['42'])]
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](disk,out/'guest',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='tcg',qmp_stdio=True,welcome=True,startup_check={'status':'ok','answers':[],'commands':commands,'pause_window_manager':False,'command_timeout':120,'rejected_answers':['1535'],'rejection_prefixes':('INPUT REJECT ','WINMGR window exception ')})
            files=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))['mutated_file_contents'](disk,{'/FatNameContract.HC'})
            if files['/FatNameContract.HC']!=FIXTURE.read_bytes():raise ValueError('Delivered fixture changed')
        else:
            if args.shared:
                original=(ROOT/'Kernel/BlkDev/FATNameCore.HC').read_text()
                expected_mask=3839
            else:
                pinned=subprocess.check_output(['git','show',ref['REFERENCE']+':Kernel/BlkDev/FileSysFAT.HC'],cwd=ROOT).decode()
                start=pinned.index('Bool FATNameTo(')
                end=pinned.index('U8 fat_long_name_map[',start)
                original=pinned[start:end]
                report['pinned_body_sha256']=hashlib.sha256(original.encode()).hexdigest()
                expected_mask=1535
            body=original.replace('FATNameTo','FNOriginalTo').replace('FATNameXSum','FNOriginalSum').replace('FATFromName','FNOriginalFrom').encode()
            source=body+FIXTURE.read_bytes().replace(b'FATNameTo',b'FNOriginalTo').replace(b'FATNameXSum',b'FNOriginalSum').replace(b'FATFromName',b'FNOriginalFrom')+b'\nU0 FNReport(U8*s){while(*s)OutU8(0xE9,*s++);}\n'
            source+=b'I64 fn_mask=FNContract;U8 *fn_line=MStrPrint("FAT NAME MASK %d\\n",fn_mask);FNReport(fn_line);Free(fn_line);FNReport("DONE fat name\\n");\n'
            (overlay/'Once.HC').write_bytes(source)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            report['iso_sha256']=sha(iso)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if f'FAT NAME MASK {expected_mask}\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original FAT name contract failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
