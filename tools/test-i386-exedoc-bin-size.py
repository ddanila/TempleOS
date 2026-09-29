#!/usr/bin/env python3
"""Require ExeDoc to execute a canonical embedded binary-size document."""

import argparse
from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/selfhost-install-gen2-fixed/target.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/exedoc-bin-size-native')
    parser.add_argument('--cpu', default='486')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    commands = [
        ('CDoc *bin_exe=DocNew("C:/Probe/BinSizeExe.HC",Fs);', []),
        ('CDocBin *bin_rec=CAlloc(sizeof(CDocBin));', []),
        ('if(TRUE){bin_rec->num=1;bin_rec->size=3;bin_rec->use_cnt=1;}', ['1']),
        ('if(TRUE){bin_rec->data=MAlloc(3);bin_rec->data[0]=1;}', ['1']),
        ('QueIns(bin_rec,bin_exe->bin_head.last);', []),
        ('CDocEntry *bin_entry=CAlloc(sizeof(CDocEntry));', []),
        ('bin_entry->type=DOCT_INS_BIN_SIZE;', ['39']),
        ('bin_entry->de_flags=DOCEF_TAG|DOCEF_HAS_BIN;', ['513']),
        ('(bin_entry->tag=StrNew(""))!=0;', ['1']),
        ('bin_entry->bin_num=1;', ['1']),
        ('(bin_entry->bin_data=bin_rec)==bin_rec;', ['1']),
        ('DocInsEntry(bin_exe,bin_entry);DocPutKey(bin_exe,59);', []),
        ('ExeDoc(bin_exe);', ['3', '3']),
        ('DocDel(bin_exe);', []),
    ]
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    print(run_input(args.disk, args.out, startup_check={
        'status': 'ok', 'answers': [], 'commands': commands, 'command_timeout': 30},
        accel=args.accel, cpu=args.cpu, startup_timeout=180))


if __name__ == '__main__':
    main()
