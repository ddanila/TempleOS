#!/usr/bin/env python3
"""Diagnostic host link of a guest-built bootstrap kernel into a QEMU disk.

This checks boot compatibility while the on-machine image publisher is built.
The input disk supplies the BIOS stage and RedSea installation unchanged.
"""
import argparse
import struct
from pathlib import Path

MODULES=('Kernel','SysTry','TaskContext','ExceptContext','IrqEntry','ExceptionEntry')
LOAD_ADDRESS=0x11000
BOOT_SECTORS=944
STAGE_BYTES=4096


def module(path):
    blob=path.read_bytes()
    if len(blob)<32:
        raise ValueError(f'{path}: short module')
    magic,version,cpu,pointer,abi,total,size,count,records,strings=struct.unpack_from('<IHBB6I',blob)
    if (magic!=0x4D323354 or version not in (2,3,4) or cpu!=3 or pointer!=4 or abi!=1 or
            total!=len(blob) or records!=32+size or strings!=records+16*count or strings>total):
        raise ValueError(f'{path}: invalid module header')
    rows=[]
    for index in range(count):
        kind,offset,name,length=struct.unpack_from('<4I',blob,records+16*index)
        if kind in (1,2,3,5,7):
            if not length or name<strings or name+length>=total or blob[name+length]:
                raise ValueError(f'{path}: invalid symbol record {index}')
            name=blob[name:name+length].decode('ascii')
        elif kind not in (4,6):
            raise ValueError(f'{path}: unknown record {index}')
        if kind in (1,3) and offset>=size:
            raise ValueError(f'{path}: export outside payload')
        if kind==4 and (not name or length or offset>size-name):
            raise ValueError(f'{path}: invalid data range')
        if kind==6 and (version<3 or length or name>=size or offset>size-4):
            raise ValueError(f'{path}: invalid local pointer')
        if kind in (2,5,7) and (offset>size-4 or struct.unpack_from('<I',blob,32+offset)[0]):
            raise ValueError(f'{path}: invalid zeroed relocation')
        rows.append((kind,offset,name,length))
    return blob[32:32+size],rows


def link(paths):
    parts=[module(path) for path in paths]
    starts=[];cursor=8;exports={}
    for code,rows in parts:
        starts.append(cursor)
        for kind,offset,name,_ in rows:
            if kind in (1,3):
                if name in exports or offset>=len(code):
                    raise ValueError(f'duplicate or invalid export: {name}')
                exports[name]=(cursor+offset,kind)
        cursor+=len(code)
    if 'Main' not in exports or exports['Main'][1]!=1:
        raise ValueError('missing unique Main entry')
    if cursor>BOOT_SECTORS*512-STAGE_BYTES:
        raise ValueError(f'flat image {cursor} exceeds BIOS reservation')
    image=bytearray(cursor)
    image[:8]=b'\xe9'+struct.pack('<I',exports['Main'][0]-5)+b'\0\0\0'
    for (code,rows),base in zip(parts,starts):
        image[base:base+len(code)]=code
        for kind,offset,name,length in rows:
            if kind in (1,3,4):
                continue
            if kind in (2,5,7):
                if name not in exports:
                    raise ValueError(f'unresolved {name}')
                target,target_kind=exports[name]
                if kind==2 and target_kind!=1:
                    raise ValueError(f'call target is not a function: {name}')
            elif kind==6:
                target=base+name
            else:
                raise ValueError(f'unsupported record kind {kind}')
            if offset>len(code)-4 or struct.unpack_from('<I',code,offset)[0]:
                raise ValueError(f'invalid patch offset {offset}')
            if kind in (2,5):
                value=target-(base+offset+4)
            else:
                value=LOAD_ADDRESS+target
            struct.pack_into('<I',image,base+offset,value&0xFFFFFFFF)
    return bytes(image)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('guest_kernel',type=Path)
    parser.add_argument('exports',type=Path)
    parser.add_argument('source_disk',type=Path)
    parser.add_argument('output_disk',type=Path)
    args=parser.parse_args()
    if args.source_disk.resolve()==args.output_disk.resolve():
        raise ValueError('source and output disks must differ')
    host=link([args.exports/f'{name}.t32m' for name in MODULES])
    original=(args.exports/'Kernel32.BIN').read_bytes()
    if host!=original:
        raise ValueError('diagnostic linker does not reproduce the host flat image')
    paths=[args.guest_kernel]+[args.exports/f'{name}.t32m' for name in MODULES[1:]]
    image=link(paths)
    disk=bytearray(args.source_disk.read_bytes())
    start=512+STAGE_BYTES
    end=512+BOOT_SECTORS*512
    if (len(disk)!=16*1024*1024 or disk[start:start+len(original)]!=original or
            any(disk[start+len(original):end])):
        raise ValueError('unexpected source disk size or boot payload')
    disk[start:end]=image+bytes(end-start-len(image))
    if disk[2048*512:]!=args.source_disk.read_bytes()[2048*512:]:
        raise ValueError('link changed filesystem sectors')
    args.output_disk.write_bytes(disk)
    print(f'linked {len(image)} flat bytes into {args.output_disk}')


if __name__=='__main__':
    main()
