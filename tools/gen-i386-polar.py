#!/usr/bin/env python3
"""Generate independent no-FPU Arg expectations."""
import argparse
from pathlib import Path
from i386_polar_oracle import vectors
ROOT = Path(__file__).resolve().parents[1]


def generate():
    rows = vectors()
    source = '#include "/Kernel/Types.HH"\n#define TRUE 1\n#define FALSE 0\n'
    source += '#include "/Kernel/I386/SoftF64.HH"\n#include "/Kernel/I386/Float.HH"\n#include "/Kernel/I386/FloatPolar.HC"\n'
    source += f'U64 polar_vectors[{len(rows)*3}]={{\n'
    source += ',\n'.join('  '+','.join(f'0x{x:016X}' for x in row) for row in rows)+'\n};\n'
    source += '''Bool PolarMatches(U64 actual,U64 expected)
{
  if(!(expected&0x7FFFFFFFFFFFFFFF))return actual==expected;
  if((actual^expected)>>63)return FALSE;
  if(actual>expected)return actual-expected<=1;
  return expected-actual<=1;
}
I64 Main(I64 a,I64 b)
{
  I64 i;F64 result;
  for(i=0;i<1024;i++) {
    result=I386PolarArg(polar_vectors[i*3](F64),polar_vectors[i*3+1](F64));
    if(!PolarMatches(result(U64),polar_vectors[i*3+2]))return i+1;
  }
  return 0;
}
#include "/Kernel/I386/SoftF64.HC"
'''
    return source


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    target = ROOT/'tests/guest/i386-soft-f64-polar/Target.HC'
    source = generate()
    if args.check:
        if target.read_text() != source:
            raise SystemExit('Regenerate independent polar fixture')
        print('Verified 1024 independent Arg vectors at 400/480 digits')
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(source)
