#!/usr/bin/env python3
"""Check original MountFile filesystem offset, real path access, read-only media and unmount lifecycle."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[1]
def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--accel',choices=('tcg','kvm'),default='kvm');args=ap.parse_args()
    out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-mount-file/Contract.HC';build=ROOT/'tools/build-i386-kernel.py'
    helper=ROOT/'tools/test-i386-timeclock-welcome.py';manifest=ROOT/'build/rebuild-test/result.json'
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    paths=[Path(__file__).resolve(),fixture,build,helper,ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py',ROOT/'Kernel/FontStd.HC']
    if args.disk:paths.append(args.disk.resolve())
    else:
        snapshot=json.loads(manifest.read_text())
        if snapshot.get('result')!='pass':raise ValueError('Qualified original rebuild required')
        paths.append(manifest)
        for name,relative in [('Kernel.BIN','0000Boot/0000Kernel.BIN.C'),('Compiler.BIN','Compiler/Compiler.BIN')]:
            p=ROOT/'build/rebuild-test/overlay'/relative
            if sha(p)!=snapshot['generations'][-1][name]:raise ValueError('Rebuild binary mismatch')
            paths.append(p)
    paths += [ROOT/n for n in ['Adam/ABlkDev/MountFileCore.HC','Kernel/BlkDev/BlockDevAddCore.HC','Kernel/BlkDev/BlockDevDeleteCore.HC','Kernel/BlkDev/FATInitCore.HC','Kernel/BlkDev/FileReadWriteCore.HC','Kernel/BlkDev/FileFindCore.HC','Kernel/BlkDev/DirectoryChangeCore.HC','Kernel/BlkDev/DirectoryMakeCore.HC']]
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',mode='native' if args.disk else 'rebuilt-original',input_sha256=pins,scope='Original complete MountFile and Unmount with offset-88 RedSea RAM image, full mapped path reads, directory changes, backing lock forwarding and write rejection; no optical hardware or FAT partition qualification')
    try:
        if args.disk:
            image=out/'working.img';b=runpy.run_path(str(build))
            runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),image,additions={'/MountContract.HC':fixture.read_bytes()})
            runpy.run_path(str(helper))['guest'](image,out/'guest',['#include "C:/MountContract.HC"','MountFileContract(67);','6*7;'],64,True,accel=args.accel)
            if b['mutated_file_contents'](image,{'/MountContract.HC'})['/MountContract.HC']!=fixture.read_bytes():raise ValueError('Delivered fixture changed')
            report['filesystem_integrity']=b['verify_mutated_volume'](image)
        else:
            overlay=out/'overlay';overlay.mkdir()
            suffix=b'\nU0 CPReport(U8*s){while(*s)OutU8(0xE9,*s++);}\ntry {MountFileContract(66);CPReport("PASS Mount File\\n");}catch {Fs->catch_except=TRUE;U8 *line=MStrPrint("OBS Mount exception %X\\n",Fs->except_ch);CPReport(line);Free(line);CPReport("FAIL Mount File\\n");}\nCPReport("DONE Mount File\\n");\n'
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+suffix)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if 'PASS Mount File\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original contract did not pass')
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(Path(p).is_file() and sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])
    print('PASS: complete MountFile contract; inputs unchanged')
if __name__=='__main__':main()
