#!/usr/bin/env python3
"""Compare host and guest I386HeapValid inline assembly and branch targets."""
import argparse
from pathlib import Path
import re
import struct
import subprocess
import tempfile

START=bytes.fromhex('8b 5d 08 8b 33 8b 4b 04 33 ff 33 d2')
END=bytes.fromhex('c6 45 ff 01')
BRANCHES={'jb','ja','je','jne','jmp'}
DESCRIPTORS={
    'I386GdtLoad':bytes.fromhex('8d45f80f0110'),
    'I386GdtRead':bytes.fromhex('8b45080f0100'),
    'I386IdtLoad':bytes.fromhex('8d45f80f0118'),
    'I386IdtRead':bytes.fromhex('8b45080f0108'),
}


def descriptor_assembly(path):
    blob=path.read_bytes()
    magic,version,cpu,pointer,abi,total,size,count,records,strings=struct.unpack_from('<IHBB6I',blob)
    if (magic!=0x4D323354 or version not in (2,3) or cpu!=3 or pointer!=4 or
            abi!=1 or total!=len(blob) or records!=32+size or
            strings!=records+16*count or strings>len(blob)):
        raise ValueError(f'{path}: invalid module')
    exports={}
    for i in range(count):
        kind,offset,name,length=struct.unpack_from('<4I',blob,records+16*i)
        if kind==1:
            if offset>=size or not length or name<strings or name+length>=len(blob):
                raise ValueError(f'{path}: invalid export')
            symbol=blob[name:name+length].decode('ascii')
            if symbol in exports:
                raise ValueError(f'{path}: duplicate export {symbol}')
            exports[symbol]=offset
    code=blob[32:32+size]
    for symbol,sequence in DESCRIPTORS.items():
        if symbol not in exports:
            raise ValueError(f'{path}: missing {symbol}')
        begin=exports[symbol]
        end=min((offset for offset in exports.values() if offset>begin),default=size)
        if code[begin:end].count(sequence)!=1:
            raise ValueError(f'{path}: missing unique {symbol} assembly')
    return True


def heap_assembly(path):
    blob=path.read_bytes()
    if len(blob)<32:
        raise ValueError(f'{path}: truncated module')
    magic,version,cpu,pointer,abi,total,size,count,records,strings=struct.unpack_from('<IHBB6I',blob)
    if (magic!=0x4D323354 or version not in (2,3) or cpu!=3 or pointer!=4 or
            abi!=1 or total!=len(blob) or records!=32+size or
            strings!=records+16*count or strings>len(blob)):
        raise ValueError(f'{path}: invalid module')
    exports=[]
    for i in range(count):
        kind,offset,name,length=struct.unpack_from('<4I',blob,records+16*i)
        if kind==1:
            if offset>=size or not length or name<strings or name+length>=len(blob):
                raise ValueError(f'{path}: invalid export')
            exports.append((offset,blob[name:name+length]))
    matches=[offset for offset,name in exports if name==b'I386HeapValid']
    if len(matches)!=1:
        raise ValueError(f'{path}: missing unique I386HeapValid export')
    start=matches[0]
    end=min((offset for offset,name in exports if offset>start),default=size)
    code=blob[32+start:32+end]
    if code.count(START)!=1:
        raise ValueError(f'{path}: missing unique heap assembly entry')
    begin=code.index(START)
    finish=code.find(END,begin)+len(END)
    if finish<len(END) or code.find(END,finish)>=0:
        raise ValueError(f'{path}: missing unique heap assembly exit')
    return code[begin:finish]


def instructions(code):
    with tempfile.NamedTemporaryFile() as binary:
        binary.write(code)
        binary.flush()
        result=subprocess.run(['objdump','-w','-D','-b','binary','-m','i386',
                               '-M','intel',binary.name],check=True,capture_output=True,text=True)
    parsed=[]
    for line in result.stdout.splitlines():
        match=re.match(r'^\s*([0-9a-f]+):\s+(?:[0-9a-f]{2}\s+)+([a-z0-9]+)(?:\s+(.*))?$',line)
        if match:
            parsed.append((int(match[1],16),match[2],(match[3] or '').strip()))
    if not parsed or parsed[0][0]!=0:
        raise ValueError('Could not disassemble heap assembly')
    addresses={offset:index for index,(offset,_,_) in enumerate(parsed)}
    addresses[len(code)]=len(parsed)
    normalized=[]
    for offset,mnemonic,operands in parsed:
        if mnemonic in BRANCHES:
            target=int(operands,16)
            if target not in addresses:
                raise ValueError(f'Branch at {offset:#x} leaves heap assembly')
            operands=f'instruction {addresses[target]}'
        normalized.append((mnemonic,operands))
    return normalized


def audit(host,guest,descriptors=False):
    original=instructions(heap_assembly(host))
    rebuilt=instructions(heap_assembly(guest))
    if original!=rebuilt:
        for index,(left,right) in enumerate(zip(original,rebuilt)):
            if left!=right:
                raise ValueError(f'Heap assembly differs at instruction {index}: {left} != {right}')
        raise ValueError(f'Heap assembly length differs: {len(original)} != {len(rebuilt)}')
    result={'result':'pass','instructions':len(original),
            'branches':sum(mnemonic in BRANCHES for mnemonic,_ in original)}
    if descriptors:
        descriptor_assembly(host)
        descriptor_assembly(guest)
        result['descriptor_functions']=len(DESCRIPTORS)
    return result


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('host',type=Path)
    parser.add_argument('guest',type=Path)
    parser.add_argument('--descriptors',action='store_true')
    args=parser.parse_args()
    print(audit(args.host,args.guest,args.descriptors))
