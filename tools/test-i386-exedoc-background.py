#!/usr/bin/env python3
"""Require ExeDoc to retain a background record inside a quoted string."""

import argparse
from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/exedoc-background')
    parser.add_argument('--cpu', default='486')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    commands = [
        ('CDoc *background_doc=DocNew("C:/Probe/QuotedBackground.HC",Fs);', []),
        ('U8 *background_prefix="U8 *s=\\"A";while(*background_prefix)DocPutKey(background_doc,*background_prefix++);', []),
        ('CDocEntry *background_color=CAlloc(sizeof(CDocEntry),background_doc->mem_task);background_color->type=DOCT_BACKGROUND;background_color->de_flags=doldoc.dft_de_flags[DOCT_BACKGROUND];', ['16', '0']),
        ('background_color->attr=1;DocInsEntry(background_doc,background_color);', ['1']),
        ('U8 *background_suffix="B\\";StrLen(s);";while(*background_suffix)DocPutKey(background_doc,*background_suffix++);', []),
        ('ExeDoc(background_doc);', ['8', '8']),
        ('DocDel(background_doc);', []),
    ]
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    print(run_input(args.disk, args.out, startup_check={
        'status': 'ok', 'answers': [], 'commands': commands, 'command_timeout': 30},
        accel=args.accel, cpu=args.cpu, startup_timeout=180))


if __name__ == '__main__':
    main()
