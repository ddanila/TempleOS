#!/usr/bin/env python3
"""Require two separately owned quoted-format documents to execute."""

import argparse
from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/exedoc-quote-repeat')
    parser.add_argument('--cpu', default='486')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    commands = []
    for suffix, value, attr, expected in (('first', 'first_text', '4', '8'),
                                          ('second', 'second_text', '15', '9'),
                                          ('default', 'default_text', 'DOC_DFT', '6')):
        doc = f'{suffix}_doc'
        prefix = f'{suffix}_prefix'
        color = f'{suffix}_color'
        tail = f'{suffix}_suffix'
        commands.extend([
            (f'CDoc *{doc}=DocNew("C:/Probe/Quoted{suffix}.HC",Fs);', []),
            (f'U8 *{prefix}="U8 *{value}=\\"A";while(*{prefix})DocPutKey({doc},*{prefix}++);', []),
            (f'CDocEntry *{color}=CAlloc(sizeof(CDocEntry),{doc}->mem_task);{color}->type=DOCT_FOREGROUND;{color}->de_flags=doldoc.dft_de_flags[DOCT_FOREGROUND];', ['15', '0']),
            (f'{color}->attr={attr};DocInsEntry({doc},{color});',
             ['-2147483648' if attr == 'DOC_DFT' else attr]),
            (f'U8 *{tail}="B\\";StrLen({value});";while(*{tail})DocPutKey({doc},*{tail}++);', []),
            (f'ExeDoc({doc});', [expected, expected]),
            (f'DocDel({doc});', []),
        ])
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    print(run_input(args.disk, args.out, startup_check={
        'status': 'ok', 'answers': [], 'commands': commands, 'command_timeout': 30},
        accel=args.accel, cpu=args.cpu, startup_timeout=180))


if __name__ == '__main__':
    main()
