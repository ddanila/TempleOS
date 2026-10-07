#!/usr/bin/env python3
"""Generate native reducer fixtures from independent Decimal expectations."""
import argparse
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[1]


def generate():
    reference = runpy.run_path(str(ROOT/'tools/test-i386-trig-reduction.py'))
    rows = reference['reference_rows']()
    source, _ = reference['check_source'](rows)
    body = source[source.index('I64 TrigReductionCheck()'):]
    start = body.index('    if(i==5) {')
    end = body.index('    if(q!=', start)
    body = body[:start]+body[end:]
    text = '#include "/Kernel/Types.HH"\n#define TRUE 1\n#define FALSE 0\n'
    text += '#include "/Kernel/I386/SoftF64.HH"\n#include "/Kernel/I386/Float.HH"\n'
    text += '#include "/Kernel/I386/FloatTrigReduction.HC"\n'
    values = [value for row in rows for value in row]
    text += f'U64 tr_vectors[{len(values)}]={{\n'
    for index in range(0, len(values), 4):
        text += '  '+','.join(f'0x{value:016X}' for value in values[index:index+4])
        text += (',' if index+4<len(values) else '')+'\n'
    text += '};\n'+body+'\nI64 Main(I64 a,I64 b){return TrigReductionCheck;}\n'
    text += '\n#include "/Kernel/I386/SoftF64.HC"\n'
    return text


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    target = ROOT/'tests/guest/i386-soft-f64-trig-reduce/Target.HC'
    expected = generate()
    if args.check:
        if target.read_text() != expected:
            raise SystemExit('Regenerate independent trig reducer fixture')
        print('Verified 1018 independent native trig reduction vectors')
    else:
        target.write_text(expected)
