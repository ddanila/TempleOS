#!/usr/bin/env python3
"""Require ExeDoc to return from an included file to its document source."""

import argparse
from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--disk', type=Path,
                        default=ROOT / 'build/i386-kernel/kernel.img')
    parser.add_argument('--out', type=Path,
                        default=ROOT / 'build/i386-kernel/exedoc-include')
    parser.add_argument('--cpu', default='486')
    parser.add_argument('--accel', choices=('kvm', 'tcg'), default='kvm')
    args = parser.parse_args()
    commands = [
        ('CDoc *include_doc=DocNew("C:/Probe/IncludeDoc.HC",Fs);', []),
        ('U8 *include_src="#include \\"/Kernel/I386/StrCopyCheck.HC\\"";', []),
        ('while(*include_src)DocPutKey(include_doc,*include_src++);', []),
        ('DocPutKey(include_doc,10);', []),
        ('U8 *include_call="StrCopyCheck(&StrCpy);";', []),
        ('while(*include_call)DocPutKey(include_doc,*include_call++);', []),
        ('ExeDoc(include_doc);', ['1', '1']),
        ('DocDel(include_doc);', []),
    ]
    run_input = runpy.run_path(str(ROOT / 'tools/i386-kernel-input.py'))['run_input']
    print(run_input(args.disk, args.out, startup_check={
        'status': 'ok', 'answers': [], 'commands': commands, 'command_timeout': 60},
        accel=args.accel, cpu=args.cpu, startup_timeout=180))


if __name__ == '__main__':
    main()
