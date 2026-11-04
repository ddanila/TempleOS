#!/usr/bin/env python3
"""Compare complete original Size behavior and scoped heap recovery on native."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-file-size/Contract.HC'
    paths=[Path(__file__).resolve(),fixture]+[ROOT/p for p in ['Adam/ABlkDev/FileSizeCore.HC','Kernel/ScanFlagsCore.HC','Kernel/FileUtilFlagsDefineCore.HC','Adam/ABlkDev/ADskB.HC','Kernel/StrB.HC','Kernel/KDefine.HC','tools/build-iso.py','tools/guest-run.py','tools/build-i386-kernel.py','tools/package-i386-native-image.py','tools/i386-kernel-input.py','Kernel/FontStd.HC']]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    if args.disk:paths.append(args.disk.resolve())
    else:
        manifest=ROOT/'build/rebuild-test/result.json';snapshot=json.loads(manifest.read_text())
        if snapshot.get('result')!='pass':raise ValueError('Qualified original rebuild required')
        paths.append(manifest)
        for name,relative in [('Kernel.BIN','0000Boot/0000Kernel.BIN.C'),('Compiler.BIN','Compiler/Compiler.BIN')]:
            p=ROOT/'build/rebuild-test/overlay'/relative
            if sha(p)!=snapshot['generations'][-1][name]:raise ValueError('Rebuild binary mismatch')
            paths.append(p)
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',mode='native' if args.disk else 'rebuilt-original',input_sha256=pins,scope='14 RedSea Size cases: stored/expanded/compressed/empty/missing files, recursion and file filters, original expansion/rounding interaction, 64-bit rounding, parent paths, directory records, preserved cwd and exact warmed caller heap. Complete ScanFlags: 70 flags, mixed operations, null source, unknown-name exception, partial application, empty-token rejection, trailing signs and heap recovery. Not FAT, I/O failures, arbitrary depth or full file utilities.')
    try:
        if args.disk:
            image=out/'working.img'
            runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),image,additions={'/SizeContract.HC':fixture.read_bytes()})
            commands=[('#include "C:/SizeContract.HC"',[]),('FileFlagsContract;',['31']),('FileSizeSetup(67);',['1'])]+[(f'FileSizeCase({i});',['7'])for i in range(14)]+[('6*7;',['42'])]
            report['behavior']=runpy.run_path(str(ROOT/'tools/i386-kernel-input.py'))['run_input'](image,out/'guest',snapshot=False,ram_mib=64,cpu='486,-fpu',accel='kvm',qmp_stdio=True,welcome=True,keep_window_manager=True,startup_check=dict(status='ok',answers=[],commands=commands,pause_window_manager=False,command_timeout=120))
            build=runpy.run_path(str(ROOT/'tools/build-i386-kernel.py'))
            expected={'/SizeContract.HC':fixture.read_bytes()}
            expected.update({('/'+p): (ROOT/p).read_bytes() for p in ['Adam/ABlkDev/FileSizeCore.HC','Kernel/ScanFlagsCore.HC','Kernel/FileUtilFlagsDefineCore.HC']})
            if build['mutated_file_contents'](image,set(expected))!=expected:raise ValueError('Delivered fixture or shared implementation changed')
            report['filesystem_integrity']=build['verify_mutated_volume'](image)
        else:
            overlay=out/'overlay';overlay.mkdir()
            suffix=b'\nU0 SZLog(U8*s){while(*s)OutU8(0xE9,*s++);}\nU0 SZRun(){I64 i,result=0,flags=FileFlagsContract;U8 *flag_line=MStrPrint("FILE FLAGS MASK %d\\n",flags);SZLog(flag_line);Free(flag_line);if(FileSizeSetup(66))for(i=0;i<14;i++){I64 value=FileSizeCase(i);U8 *line=MStrPrint("FILE SIZE CASE %d %d\\n",i,value);SZLog(line);Free(line);if(value==7)result++;}if(result==14 && flags==31)SZLog("PASS file size\\n");SZLog("DONE file size\\n");}\nSZRun;\n'
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+suffix);iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if 'PASS file size\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original size cases failed')
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
