#!/usr/bin/env python3
"""Exercise original or rebuilt-original FAT creation on a disposable IDE disk."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import shutil
import struct
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
FIXTURE=ROOT/'tests/guest/i386-fat-on-disk/Once.HC'
NAMES=[('SHORT.TXT',b'short'),('alphaabcdefghijklmnopqrs',b'twenty-four'),('bravobcdefghijklmnopqrstuvwxyz',b'thirty'),('charlieABCDEFGHIJKLMNOPQRSTUVWXYZ1234',b'thirty-seven')]
COLLISIONS=[('twinabcdefghijklmnop1',b'first'),('twinabcdefghijklmnop2',b'second')]

def verify_boundary(disk,start):
    with disk.open('rb') as f:
        base=start*512;f.seek(base);boot=f.read(512)
        if struct.unpack_from('<H',boot,11)[0]!=512 or boot[13]!=1:
            raise ValueError('Unexpected FAT sector or cluster size')
        reserved=struct.unpack_from('<H',boot,14)[0]
        fats=boot[16];fat_size=struct.unpack_from('<I',boot,36)[0]
        root=struct.unpack_from('<I',boot,44)[0]
        data_start=reserved+fats*fat_size
        f.seek(base+(data_start+root-2)*512);first=f.read(512)
        f.seek(base+reserved*512+root*4);next_cluster=struct.unpack('<I',f.read(4))[0]&0x0fffffff
        if not 2<=next_cluster<0x0ffffff8:raise ValueError('Root directory did not grow')
        f.seek(base+(data_start+next_cluster-2)*512);second=f.read(512)
        if first[14*32]!=0xe5 or first[15*32]!=0xe5:
            raise ValueError('Expected end-of-sector padding was not written')
        if [second[i*32] for i in range(3)]!=[0x43,2,1] or any(second[i*32+11]!=0x0f for i in range(3)):
            raise ValueError('Long-name slots did not start in the next cluster')
        if second[3*32:3*32+11]!=b'CHARLIEABCD':raise ValueError('Unexpected short alias after long-name slots')
        return {'root_cluster':root,'next_cluster':next_cluster,'padding_slots':[14,15],
                'long_ordinals':[second[i*32] for i in range(3)]}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--shared',action='store_true',help='Use verified current original rebuild and test all lengths')
    parser.add_argument('--collisions',action='store_true',help='Include colliding long-name aliases (known failure)')
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args();out=args.out.resolve()
    if args.collisions and not args.shared:parser.error('--collisions requires --shared')
    if out.exists():parser.error('Use a fresh output directory')
    out.mkdir(parents=True);overlay=out/'overlay';overlay.mkdir()
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    ref=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))
    inputs=[Path(__file__).resolve(),FIXTURE,ROOT/'tools/test-i386-timeclock-reference.py',ROOT/'tools/build-iso.py',ROOT/'tools/guest-run.py']
    for name in ('mkfs.fat','mcopy','fsck.fat','qemu-system-x86_64'):
        path=shutil.which(name)
        if not path:raise ValueError('Missing host tool: '+name)
        inputs.append(Path(path).resolve())
    report=dict(result='running',mode='shared' if args.shared else 'pinned-original',scope='Disposable ATA FAT32 partition: create, guest readback and host readback of short and long names; not native FAT or crash recovery',reference_sha256=ref['restore_reference'](overlay))
    if args.shared:
        manifest=ROOT/'build/rebuild-test/result.json';snapshot=json.loads(manifest.read_text())
        if snapshot.get('result')!='pass':raise ValueError('Need passing current original rebuild')
        inputs.append(manifest)
        for name,digest in snapshot['source_sha256'].items():
            path=ROOT/name
            if sha(path)!=digest:raise ValueError('Changed rebuilt source: '+name)
            inputs.append(path);target=overlay/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(path.read_bytes())
        for name,relative in [('Compiler.BIN','Compiler/Compiler.BIN'),('Kernel.BIN','0000Boot/0000Kernel.BIN.C')]:
            path=ROOT/'build/rebuild-test/overlay'/relative
            if sha(path)!=snapshot['generations'][-1][name]:raise ValueError('Changed rebuilt binary: '+name)
            inputs.append(path);(overlay/relative).write_bytes(path.read_bytes())
    report['input_sha256']={str(p):sha(p) for p in inputs}
    try:
        disk=out/'fat.img';sectors=262144;start=2048;count=sectors-start
        with disk.open('wb') as f:f.truncate(sectors*512)
        mbr=bytearray(512);mbr[446:462]=struct.pack('<B3sB3sII',0,b'\0\2\0',0x0c,b'\xfe\xff\xff',start,count);mbr[510:512]=b'\x55\xaa'
        with disk.open('r+b') as f:f.write(mbr)
        subprocess.run(['mkfs.fat','-F','32','-s','1','--offset',str(start),str(disk),str(count//2)],cwd=ROOT,check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        report['disk_before_sha256']=sha(disk)
        defines='#define FD_EXTENDED '+('TRUE' if args.shared else 'FALSE')+'\n#define FD_COLLISIONS '+('TRUE' if args.collisions else 'FALSE')+'\n'
        (overlay/'Once.HC').write_text(defines+'#define FD_REOPEN FALSE\n'+FIXTURE.read_text())
        iso=out/'original.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(iso)],cwd=ROOT,check=True)
        report['iso_sha256']=sha(iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(iso),'--out',str(out/'guest'),'--target-disk',str(disk),'--qmp-stdio','--timeout','180'],cwd=ROOT,check=True)
        expected=255 if args.collisions else 127 if args.shared else 7
        if f'FAT DISK MASK {expected}\n' not in (out/'guest/debug.log').read_text():raise ValueError('Guest FAT contract failed')
        if args.shared:report['boundary']=verify_boundary(disk,start)
        names=(NAMES+(COLLISIONS if args.collisions else [])+[(f'F{i:02}.TXT',b'fill') for i in range(6)]) if args.shared else NAMES[:2]
        for i,(name,data) in enumerate(names):
            path=out/f'host-read-{i}.bin'
            subprocess.run(['mcopy','-i',str(disk)+'@@'+str(start*512),'::/'+name,str(path)],cwd=ROOT,check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
            if path.read_bytes()!=data:raise ValueError('Host FAT readback differs: '+name)
        report['disk_after_write_sha256']=sha(disk)
        (overlay/'Once.HC').write_text(defines+'#define FD_REOPEN TRUE\n'+FIXTURE.read_text())
        reopen_iso=out/'reopen.iso'
        subprocess.run([sys.executable,'tools/build-iso.py','--overlay',str(overlay),'--output',str(reopen_iso)],cwd=ROOT,check=True)
        report['reopen_iso_sha256']=sha(reopen_iso)
        subprocess.run([sys.executable,'tools/guest-run.py',str(reopen_iso),'--out',str(out/'reopen'),'--target-disk',str(disk),'--qmp-stdio','--timeout','180'],cwd=ROOT,check=True)
        if f'FAT DISK MASK {expected}\n' not in (out/'reopen/debug.log').read_text():raise ValueError('Guest FAT reopen contract failed')
        report['disk_after_reopen_sha256']=sha(disk)
        if report['disk_after_reopen_sha256']!=report['disk_after_write_sha256']:raise ValueError('Reopen changed FAT disk')
        partition=out/'partition.img'
        with disk.open('rb') as src,partition.open('wb') as dst:
            src.seek(start*512)
            while block:=src.read(1024*1024):dst.write(block)
        check=subprocess.run(['fsck.fat','-n',str(partition)],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
        (out/'fsck.log').write_text(check.stdout)
        report['fsck_exit_code']=check.returncode
        if check.returncode:raise ValueError('FAT read-only filesystem check failed')
        report['result']='pass'
    except Exception as exc:
        report.update(result='fail',error=str(exc));raise
    finally:
        report['inputs_unchanged']=all(sha(Path(p))==digest for p,digest in report['input_sha256'].items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Execution inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['result']!='pass':raise ValueError(report['error'])

if __name__=='__main__':main()
