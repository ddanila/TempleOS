#!/usr/bin/env python3
"""Check original Copy/Move enumeration, streamed chunks, compression and metadata."""
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
    fixture=ROOT/'tests/guest/i386-copy-move/Contract.HC';build=ROOT/'tools/build-i386-kernel.py'
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
    paths += [ROOT/n for n in ['Kernel/BlkDev/CopySingleCore.HC','Adam/ABlkDev/CopyMoveCore.HC','Kernel/BlkDev/FilesFindCore.HC','Kernel/BlkDev/RedSeaFilesFindCore.HC','Kernel/BlkDev/FATFilesFindCore.HC','Kernel/BlkDev/IsDirCore.HC','Kernel/FileUtilityFlags.HH']]
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',mode='native' if args.disk else 'rebuilt-original',input_sha256=pins,scope='Original full Copy/Move: wildcard destination directory, >128-block streamed chunks, exact size/date, empty files, compression conversion, self/missing source, copy-delete move and repeated missing-source heap recovery; no full FAT32 paths or arbitrary failure recovery')
    try:
        if args.disk:
            image=out/'working.img';b=runpy.run_path(str(build))
            runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),image,additions={'/CopyContract.HC':fixture.read_bytes()})
            runpy.run_path(str(helper))['guest'](image,out/'guest',['#include "C:/CopyContract.HC"','CopyContract(67);','6*7;'],64,True,accel=args.accel)
            if b['mutated_file_contents'](image,{'/CopyContract.HC'})['/CopyContract.HC']!=fixture.read_bytes():raise ValueError('Delivered fixture changed')
            report['filesystem_integrity']=b['verify_mutated_volume'](image)
        else:
            overlay=out/'overlay';overlay.mkdir()
            suffix=b'\nU0 CPReport(U8*s){while(*s)OutU8(0xE9,*s++);}\ntry {CopyContract(66);CPReport("PASS Copy Move\\n");}catch {Fs->catch_except=TRUE;U8 *line=MStrPrint("OBS Copy exception %X\\n",Fs->except_ch);CPReport(line);Free(line);CPReport("FAIL Copy Move\\n");}\nCPReport("DONE Copy Move\\n");\n'
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+suffix)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if 'PASS Copy Move\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original contract did not pass')
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])
    print('PASS: original Copy/Move contract; inputs unchanged')
if __name__=='__main__':main()
