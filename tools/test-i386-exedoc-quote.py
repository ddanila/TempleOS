#!/usr/bin/env python3
"""Require ExeDoc to retain formatting inside a quoted document string."""

import argparse
from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/exedoc-quote')
    parser.add_argument('--cpu', default='486')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    commands = [
        ('CDoc *quote_doc=DocNew("C:/Probe/QuotedFormat.HC",Fs);', []),
        ('U8 *quote_prefix="U8 *s=\\"A";while(*quote_prefix)DocPutKey(quote_doc,*quote_prefix++);', []),
        ('CDocEntry *quote_color=DocEntryNewBase(quote_doc,DOCT_FOREGROUND);', []),
        ('quote_color->attr=4;DocInsEntry(quote_doc,quote_color);', ['4']),
        ('U8 *quote_suffix="B\\";StrLen(s);";while(*quote_suffix)DocPutKey(quote_doc,*quote_suffix++);', []),
        ('ExeDoc(quote_doc);', ['8', '8']),
        ('DocDel(quote_doc);', []),
    ]
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    print(run_input(args.disk, args.out, startup_check={
        'status': 'ok', 'answers': [], 'commands': commands, 'command_timeout': 30},
        accel=args.accel, cpu=args.cpu, startup_timeout=180))


if __name__ == '__main__':
    main()
