#!/usr/bin/env python3
"""Require ExeDoc to preserve page length and margin records in quotes."""

import argparse
from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/exedoc-layout')
    parser.add_argument('--cpu', default='486')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    commands = [
        ('CDoc *layout_doc=DocNew("C:/Probe/QuotedLayout.HC",Fs);', []),
        ('U8 *layout_prefix="U8 *s=\\"A";while(*layout_prefix)DocPutKey(layout_doc,*layout_prefix++);', []),
        ('CDocEntry *layout_page=CAlloc(sizeof(CDocEntry),layout_doc->mem_task);layout_page->type=DOCT_PAGE_LEN;layout_page->de_flags=doldoc.dft_de_flags[DOCT_PAGE_LEN];', ['9', '0']),
        ('layout_page->attr=80;DocInsEntry(layout_doc,layout_page);', ['80']),
        ('CDocEntry *layout_margin=CAlloc(sizeof(CDocEntry),layout_doc->mem_task);layout_margin->type=DOCT_LEFT_MARGIN;layout_margin->de_flags=doldoc.dft_de_flags[DOCT_LEFT_MARGIN];', ['10', '0']),
        ('layout_margin->attr=-2;DocInsEntry(layout_doc,layout_margin);', ['-2']),
        ('U8 *layout_suffix="B\\";StrLen(s);";while(*layout_suffix)DocPutKey(layout_doc,*layout_suffix++);', []),
        ('ExeDoc(layout_doc);', ['16', '16']),
        ('DocDel(layout_doc);', []),
    ]
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    print(run_input(args.disk, args.out, startup_check={
        'status': 'ok', 'answers': [], 'commands': commands, 'command_timeout': 30},
        accel=args.accel, cpu=args.cpu, startup_timeout=180))


if __name__ == '__main__':
    main()
