#!/usr/bin/env python3
"""Require ExeDoc to compile an attached binary as an expression."""

import argparse
from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/exedoc-binary')
    parser.add_argument('--cpu', default='486')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    commands = [
        ('CDoc *binary_doc=DocNew("C:/Probe/BinaryDoc.HC",Fs);', []),
        ('U8 *binary_prefix="U8 *p=";while(*binary_prefix)DocPutKey(binary_doc,*binary_prefix++);', []),
        ('CDocBin *binary_rec=CAlloc(sizeof(CDocBin));', []),
        ('if(TRUE){binary_rec->num=1;binary_rec->size=3;binary_rec->use_cnt=1;}', ['1']),
        ('if(TRUE){binary_rec->data=MAlloc(3);binary_rec->data[0]=7;}', ['7']),
        ('QueIns(binary_rec,binary_doc->bin_head.last);', []),
        ('CDocEntry *binary_entry=CAlloc(sizeof(CDocEntry));', []),
        ('binary_entry->type=DOCT_INS_BIN;', ['38']),
        ('binary_entry->de_flags=DOCEF_TAG|DOCEF_HAS_BIN;', ['513']),
        ('(binary_entry->tag=StrNew(""))!=0;', ['1']),
        ('binary_entry->bin_num=1;', ['1']),
        ('(binary_entry->bin_data=binary_rec)==binary_rec;', ['1']),
        ('DocInsEntry(binary_doc,binary_entry);', []),
        ('U8 *binary_suffix=";p[0];";while(*binary_suffix)DocPutKey(binary_doc,*binary_suffix++);', []),
        ('ExeDoc(binary_doc);', ['7', '7']),
        ('DocDel(binary_doc);', []),
    ]
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    print(run_input(args.disk, args.out, startup_check={
        'status': 'ok', 'answers': [], 'commands': commands, 'command_timeout': 30},
        accel=args.accel, cpu=args.cpu, startup_timeout=180))


if __name__ == '__main__':
    main()
