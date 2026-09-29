#!/usr/bin/env python3
"""Require ExeDoc to preserve shifted X/Y records inside quoted strings."""

import argparse
from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/exedoc-shifted')
    parser.add_argument('--cpu', default='486')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    commands = [
        ('CDoc *shift_doc=DocNew("C:/Probe/QuotedShifted.HC",Fs);', []),
        ('U8 *shift_prefix="U8 *s=\\"A";while(*shift_prefix)DocPutKey(shift_doc,*shift_prefix++);', []),
        ('CDocEntry *shift_x=CAlloc(sizeof(CDocEntry),shift_doc->mem_task);shift_x->type=DOCT_SHIFTED_X;shift_x->de_flags=doldoc.dft_de_flags[DOCT_SHIFTED_X];', ['24', '0']),
        ('shift_x->attr=12;DocInsEntry(shift_doc,shift_x);', ['12']),
        ('CDocEntry *shift_y=CAlloc(sizeof(CDocEntry),shift_doc->mem_task);shift_y->type=DOCT_SHIFTED_Y;shift_y->de_flags=doldoc.dft_de_flags[DOCT_SHIFTED_Y];', ['25', '0']),
        ('shift_y->attr=-34;DocInsEntry(shift_doc,shift_y);', ['-34']),
        ('U8 *shift_suffix="B\\";StrLen(s);";while(*shift_suffix)DocPutKey(shift_doc,*shift_suffix++);', []),
        ('ExeDoc(shift_doc);', ['17', '17']),
        ('DocDel(shift_doc);', []),
    ]
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    print(run_input(args.disk, args.out, startup_check={
        'status': 'ok', 'answers': [], 'commands': commands, 'command_timeout': 30},
        accel=args.accel, cpu=args.cpu, startup_timeout=180))


if __name__ == '__main__':
    main()
