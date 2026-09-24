#!/usr/bin/env python3
"""Audit executable BIOS and protected-mode boot-stage bytes for the 386 ISA."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess


ALLOWED = set('''add and call cld cli cmp dec div hlt in inc int ja jb jc jmp jnz jz
    lgdt lidt loop mov movzx or out pop push shl shr stc sti sub test xor'''.split())


def label_offset(listing, label):
    matches=[]
    for line in listing.splitlines():
        if re.search(r'\b'+re.escape(label)+r':',line):
            match=re.match(r'\s*\d+\s+([0-9A-Fa-f]{8})\s+',line)
            if match: matches.append(int(match.group(1),16))
    if len(matches)!=1: raise ValueError(f'Expected one placed {label} label')
    return matches[0]


def audit_code(code, bits):
    listing=subprocess.check_output(['ndisasm',f'-b{bits}','-'],input=code,text=False).decode()
    offset=0; count=0
    for line in listing.splitlines():
        continuation=re.fullmatch(r'\s+-([0-9A-Fa-f]+)\s*',line)
        if continuation:
            offset+=len(continuation.group(1))//2
            continue
        parts=line.split()
        if len(parts)<3 or int(parts[0],16)!=offset or not re.fullmatch(r'[0-9A-Fa-f]+',parts[1]):
            raise ValueError(f'Unclassified {bits}-bit boot bytes: {line}')
        mnemonic=parts[2].lower()
        if mnemonic not in ALLOWED:
            raise ValueError(f'Non-386 boot instruction: {line}')
        offset+=len(parts[1])//2; count+=1
    if offset!=len(code): raise ValueError('Boot disassembly did not cover its code range')
    return count


def audit(image, listing):
    boot_end=label_offset(listing,'drive')
    stage_end=label_offset(listing,'early_idt')
    if not (0<boot_end<510 and 0<stage_end<4096):
        raise ValueError('Boot code boundaries exceed reserved regions')
    if len(image)<512+4096 or image[510:512]!=b'\x55\xaa':
        raise ValueError('Missing complete BIOS and protected-mode stages')
    boot=image[:boot_end]
    stage=image[512:512+stage_end]
    return {
        'result':'pass',
        'boot16':{'offset':0,'bytes':len(boot),'instructions':audit_code(boot,16),
                  'sha256':hashlib.sha256(boot).hexdigest()},
        'stage32':{'offset':512,'bytes':len(stage),'instructions':audit_code(stage,32),
                   'sha256':hashlib.sha256(stage).hexdigest()},
        'scope':'Exact boot executable ranges before drive data and early IDT; linked module code is audited by build-i386-kernel.py',
    }


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('image',type=Path)
    parser.add_argument('listing',type=Path)
    parser.add_argument('--out',type=Path,required=True)
    args=parser.parse_args()
    result=audit(args.image.read_bytes(),args.listing.read_text())
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,indent=2)+'\n')
    print(f"PASS: 386 boot audit, {result['boot16']['instructions']} BIOS and {result['stage32']['instructions']} protected-mode instructions")


if __name__=='__main__': main()
