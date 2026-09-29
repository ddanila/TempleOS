#!/usr/bin/env python3
"""Require all simple numeric layout records inside quoted ExeDoc strings."""

import argparse
from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/exedoc-layout-all')
    parser.add_argument('--cpu', default='486')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    commands = [
        ('U0 AddQuotedLayout(CDoc *d,I64 t,I64 a){CDocEntry *e=CAlloc(sizeof(CDocEntry),d->mem_task);e->type=t;e->de_flags=doldoc.dft_de_flags[t];e->attr=a;DocInsEntry(d,e);}', []),
        ('CDoc *all_layout_doc=DocNew("C:/Probe/QuotedLayoutAll.HC",Fs);', []),
        ('U8 *all_layout_prefix="U8 *s=\\"A";while(*all_layout_prefix)DocPutKey(all_layout_doc,*all_layout_prefix++);', []),
        ('AddQuotedLayout(all_layout_doc,DOCT_PAGE_LEN,80);', []),
        ('AddQuotedLayout(all_layout_doc,DOCT_LEFT_MARGIN,-2);', []),
        ('AddQuotedLayout(all_layout_doc,DOCT_RIGHT_MARGIN,3);', []),
        ('AddQuotedLayout(all_layout_doc,DOCT_HEADER,4);', []),
        ('AddQuotedLayout(all_layout_doc,DOCT_FOOTER,5);', []),
        ('AddQuotedLayout(all_layout_doc,DOCT_INDENT,6);', []),
        ('AddQuotedLayout(all_layout_doc,DOCT_WORD_WRAP,1);', []),
        ('AddQuotedLayout(all_layout_doc,DOCT_HIGHLIGHT,1);', []),
        ('U8 *all_layout_suffix="B\\";StrLen(s);";while(*all_layout_suffix)DocPutKey(all_layout_doc,*all_layout_suffix++);', []),
        ('ExeDoc(all_layout_doc);', ['52', '52']),
        ('DocDel(all_layout_doc);', []),
    ]
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    print(run_input(args.disk, args.out, startup_check={
        'status': 'ok', 'answers': [], 'commands': commands, 'command_timeout': 30},
        accel=args.accel, cpu=args.cpu, startup_timeout=180))


if __name__ == '__main__':
    main()
