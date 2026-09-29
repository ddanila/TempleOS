#!/usr/bin/env python3
"""Require quoted ExeDoc to preserve page-break and clear records."""

import argparse
from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/exedoc-controls')
    parser.add_argument('--cpu', default='486')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    commands = [
        ('CDoc *control_doc=DocNew("C:/Probe/QuotedControls.HC",Fs);', []),
        ('U8 *control_prefix="U8 *s=\\"A";while(*control_prefix)DocPutKey(control_doc,*control_prefix++);', []),
        ('CDocEntry *control_page=CAlloc(sizeof(CDocEntry),control_doc->mem_task);control_page->type=DOCT_PAGE_BREAK;control_page->de_flags=doldoc.dft_de_flags[DOCT_PAGE_BREAK];', ['4', '0']),
        ('DocInsEntry(control_doc,control_page);', []),
        ('CDocEntry *control_clear=CAlloc(sizeof(CDocEntry),control_doc->mem_task);control_clear->type=DOCT_CLEAR;control_clear->de_flags=doldoc.dft_de_flags[DOCT_CLEAR];', ['8', '0']),
        ('DocInsEntry(control_doc,control_clear);', []),
        ('U8 *control_suffix="B\\";StrLen(s);";while(*control_suffix)DocPutKey(control_doc,*control_suffix++);', []),
        ('ExeDoc(control_doc);', ['10', '10']),
        ('DocDel(control_doc);', []),
    ]
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    print(run_input(args.disk, args.out, startup_check={
        'status': 'ok', 'answers': [], 'commands': commands, 'command_timeout': 30},
        accel=args.accel, cpu=args.cpu, startup_timeout=180))


if __name__ == '__main__':
    main()
