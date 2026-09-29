#!/usr/bin/env python3
"""Require ExeDoc to preserve default color records inside quoted strings."""

import argparse
from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/exedoc-default-colors')
    parser.add_argument('--cpu', default='486')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    commands = [
        ('CDoc *default_colors_doc=DocNew("C:/Probe/QuotedDefaultColors.HC",Fs);', []),
        ('U8 *colors_prefix="U8 *s=\\"A";while(*colors_prefix)DocPutKey(default_colors_doc,*colors_prefix++);', []),
        ('CDocEntry *default_fg=CAlloc(sizeof(CDocEntry),default_colors_doc->mem_task);default_fg->type=DOCT_DFT_FOREGROUND;default_fg->de_flags=doldoc.dft_de_flags[DOCT_DFT_FOREGROUND];', ['17', '0']),
        ('default_fg->attr=7;DocInsEntry(default_colors_doc,default_fg);', ['7']),
        ('CDocEntry *default_bg=CAlloc(sizeof(CDocEntry),default_colors_doc->mem_task);default_bg->type=DOCT_DFT_BACKGROUND;default_bg->de_flags=doldoc.dft_de_flags[DOCT_DFT_BACKGROUND];', ['18', '0']),
        ('default_bg->attr=2;DocInsEntry(default_colors_doc,default_bg);', ['2']),
        ('U8 *colors_suffix="B\\";StrLen(s);";while(*colors_suffix)DocPutKey(default_colors_doc,*colors_suffix++);', []),
        ('ExeDoc(default_colors_doc);', ['14', '14']),
        ('DocDel(default_colors_doc);', []),
    ]
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    print(run_input(args.disk, args.out, startup_check={
        'status': 'ok', 'answers': [], 'commands': commands, 'command_timeout': 30},
        accel=args.accel, cpu=args.cpu, startup_timeout=180))


if __name__ == '__main__':
    main()
