#!/usr/bin/env python3
"""Generate bootstrap keyword descriptors from the existing opcode source."""
import argparse
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def generate():
    source = (ROOT/'Compiler/OpCodes.DD').read_bytes()
    rows = re.findall(rb'^(KEYWORD|ASM_KEYWORD)\s+(\w+)\s+(\d+)\s*;', source, re.M)
    if len(rows) != 73 or len(set((kind, name) for kind, name, _ in rows)) != len(rows):
        raise ValueError('Review changed keyword inventory before regenerating')
    constants = dict(re.findall(r'^#define\s+((?:A?KW)_\w+)\s+(\d+)\s*$',
                               (ROOT/'Compiler/Keywords.HH').read_text(), re.M))
    records = []
    for kind, name, value in rows:
        kind, name, value = kind.decode(), name.decode(), int(value)
        if len(name) >= 12:
            raise ValueError('Keyword name exceeds descriptor capacity')
        constant = ('AKW_' if kind == 'ASM_KEYWORD' else 'KW_') + ('DFT' if name == 'default' else name.upper())
        if int(constants.get(constant, -1)) != value:
            raise ValueError(f'Keyword constant disagrees with opcode source: {name}')
        records.append(f'  {{"{name}",HTT_{kind},{constant}}},')
    return '#include "/Compiler/KeywordTable.HH"\n//Generated from OpCodes.DD by tools/gen-compiler-keywords.py.\nCCompilerKeyword compiler_keywords[COMPILER_KEYWORDS_NUM]={\n' + '\n'.join(records) + '\n};\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    output = ROOT/'Compiler/KeywordTable.HC'
    data = generate()
    if args.check:
        if not output.exists() or output.read_text() != data:
            raise ValueError('Stale compiler keyword descriptors; regenerate them')
    else:
        output.write_text(data)
    print('Checked 73 compiler keyword descriptors' if args.check else 'Generated 73 compiler keyword descriptors')


if __name__ == '__main__':
    main()
