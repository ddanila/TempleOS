#!/usr/bin/env python3
"""Compare original RedSeaISO generation, descriptors and mounted file round trips."""
import argparse
import hashlib
import json
from pathlib import Path
import runpy
import subprocess
import struct
import time

ROOT=Path(__file__).resolve().parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def expected_bytes(count=12):
    return struct.pack(f"<{count}q",*([1]*count))

def verify_iso(data):
    if len(data)%2048:raise ValueError('ISO size alignment')
    for block,kind in [(16,1),(17,0),(18,2),(19,255)]:
        if data[block*2048:block*2048+7]!=bytes([kind])+b'CD001\x01':raise ValueError('Descriptor header')
    pri=data[16*2048:17*2048]
    for pos,value in [(80,len(data)//2048)]:
        if struct.unpack_from('<I',pri,pos)[0]!=value or struct.unpack_from('>I',pri,pos+4)[0]!=value:raise ValueError('Volume size palindrome')
    for pos,value in [(120,1),(124,1),(128,2048)]:
        if struct.unpack_from('<H',pri,pos)[0]!=value or struct.unpack_from('>H',pri,pos+2)[0]!=value:raise ValueError('Descriptor palindrome')
    cat=data[20*2048:21*2048]
    if sum(struct.unpack('<16H',cat[:32]))&65535:raise ValueError('El Torito checksum')
    if cat[32:44]!=struct.pack('<BBHBBHI',0x88,0,0,0,0,4,21):raise ValueError('El Torito boot entry')
    offset=88*512
    if data[offset+3]!=0x88 or data[offset+510:offset+512]!=b'\x55\xaa':raise ValueError('RedSea signature')
    drive_offset,sectors,root,bitmap,unique=struct.unpack_from('<5q',data,offset+8)
    if drive_offset!=88 or (sectors+88)*512!=len(data):raise ValueError('RedSea geometry')
    if struct.unpack_from('<I',pri,152)[0]!=root or struct.unpack_from('>I',pri,156)[0]!=root:raise ValueError('Root palindrome')
    found={};dirs=set();seen=set()
    def walk(block,size,path):
        if (block,size) in seen or block*512+size>len(data) or block<88 or size<64:raise ValueError('Directory bounds/cycle')
        seen.add((block,size))
        attr,name,self_block,self_size,date=struct.unpack_from('<H38sqqQ',data,block*512)
        expected_self=path.rsplit('/',1)[-1] if path else '.'
        if name.split(b'\0',1)[0].decode('ascii')!=expected_self or not attr&16 or self_block!=block or self_size!=size:raise ValueError('Directory self record')
        parent=struct.unpack_from('<H38sqqQ',data,block*512+64)
        if parent[1].split(b'\0',1)[0]!=b'..' or not parent[0]&16:raise ValueError('Directory parent record')
        for pos in range(block*512+128,block*512+size,64):
            attr,name,child,length,date=struct.unpack_from('<H38sqqQ',data,pos)
            name=name.split(b'\0',1)[0].decode('ascii')
            if not name:break
            if name in ('.','..'):continue
            full=path+'/'+name
            if attr&16:dirs.add(full);walk(child,length,full)
            else:
                if child<88 or length<0 or child*512+length>len(data):raise ValueError('File bounds')
                found[full]=data[child*512:child*512+length]
    root_size=struct.unpack_from('<q',data,root*512+48)[0];walk(root,root_size,'')
    expected={'/Nested/Small.DATA':b'iso','/Large.DATA':bytes(i*7%256 for i in range(4097)),'/Stage2.BIN':bytes((i*11+3)%256 for i in range(1537))}
    if found!=expected or dirs!={'/Nested','/Empty'}:raise ValueError('Generated tree differs')
    return dict(result='pass',bytes=len(data),files={n:hashlib.sha256(v).hexdigest() for n,v in found.items()},directories=sorted(dirs),scope='Original RedSea ISO descriptors, catalog and recursive file bytes; synthetic stage2 is not booted')

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path,nargs='?');ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    fixture=ROOT/'tests/guest/i386-redsea-iso/Contract.HC'
    includes=[]
    paths=includes+[Path(__file__).resolve(),fixture,ROOT/'Kernel/FontStd.HC']+[ROOT/('tools/'+n) for n in ['test-i386-timeclock-reference.py','test-i386-autocomplete-interaction.py','test-i386-timeclock-welcome.py','build-iso.py','package-i386-native-image.py','build-i386-kernel.py']]
    if args.disk:paths.append(args.disk.resolve())
    out.mkdir();pins={str(p):sha(p) for p in paths};report=dict(result='running',input_sha256=pins,scope='Original RedSeaISO generates a nested tree with empty directory, multi-block file and stage2 payload; mounted byte round trips and independent host descriptor/tree validation. This does not boot the synthetic stage2.');g=None
    (out/'fixture.HC').write_bytes(fixture.read_bytes());(out/'runner-source.py').write_bytes(Path(__file__).read_bytes())
    try:
        if args.disk:
            pack=runpy.run_path(str(ROOT/'tools/package-i386-native-image.py'));image=out/'working.img'
            report['packaging']=pack['package'](args.disk.resolve(),image,additions={'/Probe/RedSeaISOCheck.HC':fixture.read_bytes(),**{'/'+p.name:p.read_bytes() for p in includes}})
        else:
            overlay=out/'overlay';overlay.mkdir();report['reference_sha256']=runpy.run_path(str(ROOT/'tools/test-i386-timeclock-reference.py'))['restore_reference'](overlay)
            (overlay/'RedSeaISOCheck.HC').write_bytes(fixture.read_bytes())
            for p in includes:(overlay/p.name).write_bytes(p.read_bytes())
            (overlay/'Once.HC').write_bytes(b'while(!Bt(&sys_run_level,RLf_ADAM_SERVER))Yield;\n#include "::/RedSeaISOCheck.HC"\nISOCheck(66);\n')
            image=out/'original.iso';subprocess.run(['python3','tools/build-iso.py','--overlay',str(overlay),'--output',str(image)],cwd=ROOT,check=True)
        Guest=runpy.run_path(str(ROOT/'tools/test-i386-autocomplete-interaction.py'))['Guest'];g=Guest(image,out/'guest',bool(args.disk))
        if args.disk:
            g.wait('DONE native kernel startup\n')
            g.command('#include "C:/Probe/RedSeaISOCheck.HC"');g.command('ISOCheck(67);')
        deadline=time.monotonic()+180
        while True:
            remaining=deadline-time.monotonic()
            if remaining<=0:raise TimeoutError('Missing guest marker: REDSEA ISO DONE')
            try:
                g.wait('REDSEA ISO DONE\n',timeout=min(30,remaining));break
            except TimeoutError:
                g.call('screendump',filename=str(out/'waiting.ppm'))
        expected={'iso-checks.bin':expected_bytes(10)}
        for name,want in expected.items():
            actual=(g.out/name).read_bytes();(out/name).write_bytes(actual)
            if actual!=want:raise ValueError(name+' differs from independent byte oracle')
        iso=(g.out/'generated.iso').read_bytes();(out/'generated.iso').write_bytes(iso)
        report['iso_structure']=verify_iso(iso)
        plain=(g.out/'default.iso').read_bytes();(out/'default.iso').write_bytes(plain)
        report['default_iso_structure']=verify_iso(plain)
        if any(plain[21*2048:22*2048]):raise ValueError('Default image unexpectedly contains stage1 bytes')
        if not any(iso[21*2048:22*2048]):raise ValueError('Explicit stage2 did not install stage1')
        if args.disk:g.command('6*7;');g.result_pixels()
        report.update(result='pass',cases_checked=1,
                      table_sha256={n:hashlib.sha256(v).hexdigest() for n,v in expected.items()})
    except Exception as exc:
        report.update(result='fail',error=str(exc))
        if g:g.call('screendump',filename=str(out/'failure.ppm'))
        raise
    finally:
        if g:g.close()
        report['inputs_unchanged']=all(p.is_file() and sha(p)==pins[str(p)] for p in paths)
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
