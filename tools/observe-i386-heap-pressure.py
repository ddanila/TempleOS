#!/usr/bin/env python3
"""Capture allocator blocks before and after a real low-memory compiler request."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import runpy
import shutil
import struct
ROOT=Path(__file__).resolve().parents[1]

def blocks(data,base):
    result=[];pos=0
    while pos<len(data):
        span,requested,tag,reserved=struct.unpack_from('<4I',data,pos)
        if span<16 or span&7 or pos+span>len(data) or reserved or tag not in (0x46523349,0x55523349):raise ValueError(f'Invalid block at {base+pos:X}')
        if tag==0x55523349 and requested>span-16:raise ValueError('Invalid requested size')
        result.append(dict(address=base+pos+16,span=span,requested=requested,used=tag==0x55523349,prefix=data[pos+16:pos+48].hex()))
        pos+=span
    return result

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('disk',type=Path);ap.add_argument('--out',type=Path,required=True);args=ap.parse_args();out=args.out.resolve()
    if out.exists():ap.error('Use a fresh output directory')
    out.mkdir();image=out/'working.img';shutil.copyfile(args.disk,image)
    helper=ROOT/'tools/test-i386-autocomplete-interaction.py';paths=[Path(__file__).resolve(),helper,args.disk.resolve(),ROOT/'Kernel/I386/Heap.HH',ROOT/'Kernel/SymbolTypes.HH']
    for path,name in [(Path(__file__).resolve(),'runner-source.py'),(helper,'helper-source.py')]:copy=out/name;copy.write_bytes(path.read_bytes());paths.append(copy)
    sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest();pins={str(p):sha(p) for p in paths}
    report=dict(result='running',input_sha256=pins,ram_mib=8,cpu='486,-fpu',accel='kvm',scope='Read-only physical heap census around actual canonical symbol header loading. Not a memory fix or service qualification.')
    guest=None
    try:
        guest=runpy.run_path(str(helper))['Guest'](image,out/'guest',True,ram_mib=8);text=guest.wait('DONE native kernel startup\n')
        arenas=[]
        for label,pattern in [('main',r'^ARENA ([0-9A-F]+) ([0-9A-F]+)$'),('fallback',r'^TASK FALLBACK ARENA ([0-9A-F]+) ([0-9A-F]+)$')]:
            match=re.search(pattern,text,re.M)
            if not match:raise ValueError('Missing '+label+' arena')
            arenas.append((label,int(match[1],16),int(match[2],16)))
        def capture(phase):
            guest.call('stop')
            try:
                for label,base,size in arenas:guest.call('pmemsave',val=base,size=size,filename=str(out/f'{phase}-{label}.bin'))
                guest.screenshot(phase)
            finally:guest.call('cont')
            groups={}
            for label,base,size in arenas:
                rows=blocks((out/f'{phase}-{label}.bin').read_bytes(),base);live=[r for r in rows if r['used']];free=[r for r in rows if not r['used']]
                histogram=Counter(r['requested'] for r in live)
                groups[label]=dict(base=base,size=size,used_spans=sum(r['span'] for r in live),requested=sum(r['requested'] for r in live),allocations=len(live),free=sum(r['span'] for r in free),largest_free=max((r['span']-16 for r in free),default=0),largest=sorted(live,key=lambda row:row['span'],reverse=True)[:30],histogram=histogram)
                (out/f'{phase}-{label}-blocks.json').write_text(json.dumps(rows,indent=2)+'\n')
            report[phase]=groups
        capture('boot')
        start=len(guest.collect());guest.type('#include "/Kernel/SymbolTypes.HH"');guest.press('ret')
        import time
        deadline=time.monotonic()+90
        while True:
            log=guest.collect()[start:]
            if 'COMMAND OK\n' in log or 'COMMAND ERROR\n' in log:break
            if time.monotonic()>deadline:raise TimeoutError('Header request did not finish')
            time.sleep(.1)
        capture('after');report['command_log']=log;report['header_accepted']='COMMAND OK\n' in log
        guest.close();guest=None;report['result']='pass'
    except Exception as exc:report.update(result='fail',error=str(exc));raise
    finally:
        if guest:guest.close()
        report['inputs_unchanged']=all(sha(Path(p))==h for p,h in pins.items())
        if not report['inputs_unchanged']:report.update(result='fail',error='Inputs changed')
        (out/'result.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__=='__main__':main()
