#!/usr/bin/env python3
"""Require three consecutive style records inside a quoted document string."""

import argparse
from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/exedoc-style')
    parser.add_argument('--cpu', default='486')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    commands = [
        ('CDoc *style_doc=DocNew("C:/Probe/QuotedStyles.HC",Fs);', []),
        ('U8 *style_prefix="U8 *s=\\"A";while(*style_prefix)DocPutKey(style_doc,*style_prefix++);', []),
    ]
    for name, record, code in (('blink', 'DOCT_BLINK', '21'),
                               ('invert', 'DOCT_INVERT', '22'),
                               ('underline', 'DOCT_UNDERLINE', '23')):
        commands.extend([
            (f'CDocEntry *{name}_entry=CAlloc(sizeof(CDocEntry),style_doc->mem_task);', []),
            (f'{name}_entry->type={record};{name}_entry->de_flags=doldoc.dft_de_flags[{record}];',
             [code, '0']),
            (f'{name}_entry->attr=1;DocInsEntry(style_doc,{name}_entry);', ['1']),
        ])
    commands.extend([
        ('U8 *style_suffix="B\\";StrLen(s);";while(*style_suffix)DocPutKey(style_doc,*style_suffix++);', []),
        ('ExeDoc(style_doc);', ['20', '20']),
        ('DocDel(style_doc);', []),
    ])
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    print(run_input(args.disk, args.out, startup_check={
        'status': 'ok', 'answers': [], 'commands': commands, 'command_timeout': 30},
        accel=args.accel, cpu=args.cpu, startup_timeout=180))


if __name__ == '__main__':
    main()
