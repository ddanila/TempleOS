#!/usr/bin/env python3
"""Check original Complete original FAT32 formatting and public filesystem paths."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[1]
def verify_fat(raw):
    import struct
    word=lambda off:struct.unpack_from('<H',raw,off)[0]
    dword=lambda off:struct.unpack_from('<I',raw,off)[0]
    if len(raw)!=2097152 or word(510)!=0xAA55 or word(11)!=512 or raw[16]!=2:
        raise ValueError('Invalid formatted FAT boot record')
    spc=raw[13];reserved=word(14);sectors=dword(36);root=dword(44)
    one=raw[reserved*512:(reserved+sectors)*512]
    two=raw[(reserved+sectors)*512:(reserved+2*sectors)*512]
    if one!=two:raise ValueError('FAT mirrors differ')
    data=(reserved+2*sectors)*512
    owned=set()
    def chain(cluster):
        result=bytearray();seen=set()
        while cluster<0x0FFFFFF8:
            if cluster<2 or cluster in seen or cluster in owned:raise ValueError('Invalid or overlapping FAT chain')
            seen.add(cluster);owned.add(cluster)
            off=data+(cluster-2)*spc*512
            if off<0 or off+spc*512>len(raw):raise ValueError('FAT extent outside image')
            result+=raw[off:off+spc*512]
            cluster=struct.unpack_from('<I',one,cluster*4)[0]&0x0FFFFFFF
        return bytes(result)
    def directory(cluster):
        entries={};long=[]
        for off in range(0,len(buf:=chain(cluster)),32):
            e=buf[off:off+32]
            if not e[0]:break
            if e[0]==0xE5:long=[];continue
            if e[11]==15:
                name=(e[1:11]+e[14:26]+e[28:32]).decode('utf-16le').split('\0')[0].replace('\uffff','')
                long.insert(0,name);continue
            short=e[:8].decode('ascii').rstrip();ext=e[8:11].decode('ascii').rstrip()
            name=''.join(long) if long else short+('.'+ext if ext else '')
            long=[]
            if name not in ('.','..'):
                cluster=struct.unpack_from('<H',e,26)[0]|struct.unpack_from('<H',e,20)[0]<<16
                entries[name.casefold()]=(e[11],cluster,struct.unpack_from('<I',e,28)[0])
        return entries
    top=directory(root)
    if set(top)!={'sub'} or not top['sub'][0]&16:raise ValueError('Missing Sub directory')
    sub=directory(top['sub'][1])
    wanted={'grand','alpha.data','beta.data.z','long sample name.data','moved.data','stream.data'}
    if set(sub)!=wanted:raise ValueError(f'Unexpected Sub entries: {set(sub)}')
    expected=bytes((i*17+i//512)&255 for i in range(1537))
    for name,(attr,cluster,size) in sub.items():
        if name=='grand':
            if not attr&16 or directory(cluster):raise ValueError('Grand directory not empty')
        else:
            content=chain(cluster)[:size]
            if name!='beta.data.z' and content!=expected[:1536 if name=='stream.data' else 1537]:
                raise ValueError('Independent file-content mismatch: '+name)
            if name=='beta.data.z' and (len(content)<17 or struct.unpack_from('<Q',content,8)[0]!=1537):
                raise ValueError('Compressed stream metadata mismatch')
    return dict(mirrors_equal=True,live_clusters=len(owned),files=5,directories=3,plain_contents_exact=True)

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--accel',choices=('tcg','kvm'),default='kvm');args=ap.parse_args()
    out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir(parents=True)
    fixture=ROOT/'tests/guest/i386-fat-path/Contract.HC';build=ROOT/'tools/build-i386-kernel.py'
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
    paths += [ROOT/n for n in ['Adam/ABlkDev/MountFileCore.HC','Kernel/BlkDev/BlockDevAddCore.HC','Kernel/BlkDev/BlockDevDeleteCore.HC','Kernel/BlkDev/FATInitCore.HC','Kernel/BlkDev/FileReadWriteCore.HC','Kernel/BlkDev/FileFindCore.HC','Kernel/BlkDev/DirectoryChangeCore.HC','Kernel/BlkDev/DirectoryMakeCore.HC','Kernel/BlkDev/FATFormatCore.HC','Kernel/BlkDev/DirectoryLinksCore.HC','Kernel/BlkDev/DirectoryListCore.HC']]
    pins={str(p):sha(p) for p in paths}
    report=dict(result='running',mode='native' if args.disk else 'rebuilt-original',input_sha256=pins,scope='Complete FAT32 format/init and public path services on a private 4096-sector RAM device, directory creation, long names, compression, Copy/Move, CFile streams, parent and relative reads, enumeration and full listing; not ATA hardware, crash recovery or large-volume FAT32 qualification')
    try:
        if args.disk:
            image=out/'working.img';b=runpy.run_path(str(build))
            runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'))['package'](args.disk.resolve(),image,additions={'/FatContract.HC':fixture.read_bytes()})
            runpy.run_path(str(helper))['guest'](image,out/'guest',['#include "C:/FatContract.HC"','U8 *fat_snapshot=FatPathContract;','FileWrite("C:/FatPath.RAW",fat_snapshot,2097152);Free(fat_snapshot);','6*7;'],64,True,accel=args.accel)
            if b['mutated_file_contents'](image,{'/FatContract.HC'})['/FatContract.HC']!=fixture.read_bytes():raise ValueError('Delivered fixture changed')
            report['filesystem_integrity']=b['verify_mutated_volume'](image)
            raw=b['mutated_file_contents'](image,{'/FatPath.RAW'})['/FatPath.RAW']
            (out/'FatPath.RAW').write_bytes(raw)
        else:
            overlay=out/'overlay';overlay.mkdir()
            suffix=b'\nU0 CPReport(U8*s){while(*s)OutU8(0xE9,*s++);}\nU0 FPRun(){U8 *snapshot;try {snapshot=FatPathContract;U8 *export=MStrPrint("EXPORT FatPath.RAW %X 200000\\n",snapshot);CPReport(export);Free(export);CPReport("PASS FAT Paths\\n");}catch {Fs->catch_except=TRUE;U8 *line=MStrPrint("OBS FAT exception %X\\n",Fs->except_ch);CPReport(line);Free(line);CPReport("FAIL FAT Paths\\n");}\nCPReport("DONE FAT Paths\\n");}\nFPRun;\n'
            (overlay/'Once.HC').write_bytes(fixture.read_bytes()+suffix)
            iso=out/'original.iso'
            subprocess.run([sys.executable,'tools/build-iso.py','--overlay','build/rebuild-test/overlay','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
            subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--qmp-stdio','--timeout','120'],cwd=ROOT,check=True)
            if 'PASS FAT Paths\n' not in (out/'guest/debug.log').read_text():raise ValueError('Original contract did not pass')
        if not args.disk:raw=(out/'guest/FatPath.RAW').read_bytes()
        report['fat_integrity']=verify_fat(raw)
        report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(Path(p).is_file() and sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])
    print('PASS: complete FAT32 path contract; inputs unchanged')
if __name__=='__main__':main()
