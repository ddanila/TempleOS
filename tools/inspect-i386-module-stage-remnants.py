#!/usr/bin/env python3
"""Compare a failed retained-build disk with its input for staged T32M remnants."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

HEADER=struct.Struct('<IHBB6I')
MAGIC=0x4D323354

def sha(data):
    return hashlib.sha256(data).hexdigest()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('before',type=Path)
    parser.add_argument('after',type=Path)
    parser.add_argument('--bytes',type=lambda s:int(s,0),required=True)
    parser.add_argument('--result',type=Path,help='Require retained-build input and output hashes to match')
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    if args.out.exists():parser.error('Use a fresh output file')
    before=args.before.read_bytes();after=args.after.read_bytes()
    if len(before)!=len(after) or len(after)%512:raise ValueError('Images must have equal sector-aligned lengths')
    if args.result:
        result=json.loads(args.result.read_text())
        if result.get('result')!='fail' or result.get('input_disk_sha256')!=sha(before) or result.get('source_disk_sha256')!=sha(after):
            raise ValueError('Images do not match a failed retained-build result')
    candidates=[]
    for pos in range(0,len(after)-HEADER.size+1,512):
        if after[pos:pos+4]!=b'T32M' or before[pos:pos+4]==b'T32M':continue
        magic,version,cpu,pointer,abi,total,code,records,records_offset,strings_offset=HEADER.unpack_from(after,pos)
        if (magic!=MAGIC or version not in (2,3,4) or cpu!=3 or pointer!=4 or abi!=1 or
            total!=args.bytes or total<32 or code%8 or records_offset!=32+code or
            strings_offset!=records_offset+records*16 or strings_offset>total or
            pos+((total+511)//512)*512>len(after)):
            continue
        candidates.append((pos,total,code,records,records_offset,strings_offset))
    if len(candidates)!=1:raise ValueError(f'Expected one new matching header, found {len(candidates)}')
    pos,total,code,records,records_offset,strings_offset=candidates[0]
    blocks=(total+511)//512
    changed=[i for i in range(blocks) if before[pos+i*512:pos+(i+1)*512]!=after[pos+i*512:pos+(i+1)*512]]
    if not changed or changed[0]!=0:raise ValueError('Header sector did not change')
    report={'result':'pass','before_sha256':sha(before),'after_sha256':sha(after),
            'header_sector':pos//512,'module_bytes':total,'code_bytes':code,'records':records,
            'records_offset':records_offset,'strings_offset':strings_offset,'extent_sectors':blocks,
            'changed_sector_count':len(changed),'first_changed_relative_sector':changed[0],
            'last_changed_relative_sector':changed[-1],
            'scope':'Changed sectors in a released extent; not an exact write count or failure cause'}
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report))

if __name__=='__main__':main()
