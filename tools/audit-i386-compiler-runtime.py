#!/usr/bin/env python3
"""Compare a guest-built compiler runtime against the host-assembled T32M."""
import argparse
import hashlib
import json
from pathlib import Path
import struct


def parse(path):
    blob=path.read_bytes()
    if len(blob)<32:
        raise ValueError(f'{path}: truncated module')
    magic,version,cpu,pointer,abi,total,size,count,records,strings=struct.unpack_from('<IHBB6I',blob)
    if (magic,cpu,pointer,abi,total,records,strings)!=(
            0x4D323354,3,4,1,len(blob),32+size,32+size+16*count) or \
            version not in (2,3) or strings>len(blob):
        raise ValueError(f'{path}: invalid T32M header')
    names={kind:{} for kind in (1,2,3,5)}
    ranges=[]
    pointers=[]
    for i in range(count):
        kind,offset,name,length=struct.unpack_from('<4I',blob,records+16*i)
        if kind==4:
            if not name or offset>size-name or length:
                raise ValueError(f'{path}: invalid data range {i}')
            ranges.append((offset,offset+name))
            continue
        if kind==6:
            if version<3 or length or offset>size-4 or name>=size or struct.unpack_from('<I',blob,32+offset)[0]:
                raise ValueError(f'{path}: invalid local pointer {i}')
            pointers.append((offset,name))
            continue
        if (kind not in names or offset>=size or not length or
                name<strings or name+length>=len(blob) or blob[name+length] or
                b'\0' in blob[name:name+length]):
            raise ValueError(f'{path}: invalid record {i}')
        symbol=blob[name:name+length].decode('ascii')
        if kind in (2,5):
            if offset>size-4 or struct.unpack_from('<I',blob,32+offset)[0]:
                raise ValueError(f'{path}: invalid relocation {i}')
        if kind in (1,3) and symbol in names[kind]:
            raise ValueError(f'{path}: duplicate export {symbol}')
        names[kind].setdefault(symbol,[]).append(offset)
    ranges.sort()
    if any(left[1]>right[0] for left,right in zip(ranges,ranges[1:])):
        raise ValueError(f'{path}: overlapping data ranges')
    for offset,target in pointers:
        if not any(begin<=offset and offset+4<=end for begin,end in ranges) or not any(
                begin<=target<end for begin,end in ranges):
            raise ValueError(f'{path}: local pointer outside data')
    for kind in (1,3):
        for symbol,offsets in names[kind].items():
            inside=any(begin<=offsets[0]<end for begin,end in ranges)
            if inside!=(kind==3):
                raise ValueError(f'{path}: misplaced export {symbol}')
    return {'blob':blob,'code':blob[32:32+size],'names':names,'ranges':ranges,
            'pointers':pointers,
            'sha256':hashlib.sha256(blob).hexdigest()}


def audit(host_path,guest_path,second_path=None):
    host=parse(host_path); guest=parse(guest_path)
    h=host['names']; g=guest['names']
    if set(h[1])-set(g[1])!={'_I386_DIV_BEGIN','_I386_DIV_END'} or set(g[1])-set(h[1]):
        raise ValueError('Guest function exports differ from host compiler runtime')
    if set(g[3])-set(h[3])!={'I386DivTemplate'} or set(h[3])-set(g[3]):
        raise ValueError('Guest data exports differ from host compiler runtime')
    if set(g[2])-set(g[1])!=set(h[2]):
        raise ValueError('Guest resident call imports differ from host compiler runtime')
    if set(g[5])-set(g[1])-set(g[3])!=set(h[5]):
        raise ValueError('Guest resident address imports differ from host compiler runtime')
    polls=g[2].get('I386ExecutionBreakPoll',[])
    if not polls or any(guest['code'][offset-1]!=0xE8 for offset in polls):
        raise ValueError('Guest break checkpoints lack named call relocations')
    begin=h[1]['_I386_DIV_BEGIN'][0]; end=h[1]['_I386_DIV_END'][0]
    target=g[3]['I386DivTemplate'][0]
    if end-begin!=185 or guest['code'][target:target+185]!=host['code'][begin:end] or not any(
            start<=target and target+185<=finish for start,finish in guest['ranges']):
        raise ValueError('Guest division template differs from host assembly')
    if second_path and parse(second_path)['blob']!=guest['blob']:
        raise ValueError('Guest compiler runtime builds are not byte-identical')
    return {'result':'pass','guest_bytes':len(guest['blob']),'guest_sha256':guest['sha256'],
            'function_exports':len(g[1]),'data_exports':len(g[3]),
            'call_relocations':sum(map(len,g[2].values())),
            'break_poll_relocations':len(polls),
            'address_relocations':sum(map(len,g[5].values())),
            'resident_calls':sorted(set(g[2])-set(g[1])),
            'resident_addresses':sorted(set(g[5])-set(g[1])-set(g[3])),
            'byte_identical_second_build':bool(second_path)}


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('host',type=Path)
    parser.add_argument('guest',type=Path)
    parser.add_argument('second',type=Path,nargs='?')
    args=parser.parse_args()
    print(json.dumps(audit(args.host,args.guest,args.second),indent=2))
