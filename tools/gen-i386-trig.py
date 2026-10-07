#!/usr/bin/env python3
"""Generate no-FPU Sin/Cos checks from the independent Decimal oracle."""
import argparse
from pathlib import Path
import struct
from i386_trig_oracle import make_trig_oracle

ROOT = Path(__file__).resolve().parents[1]


def generate():
    values = [v for row in struct.iter_unpack('<3Q', make_trig_oracle()) for v in row]
    source = '#include "/Kernel/Types.HH"\n#define TRUE 1\n#define FALSE 0\n'
    source += '#include "/Kernel/I386/SoftF64.HH"\n#include "/Kernel/I386/Float.HH"\n'
    source += '#include "/Kernel/I386/FloatTrig.HC"\n'
    source += f'U64 trig_vectors[{len(values)}]={{\n'
    for index in range(0, len(values), 3):
        source += '  '+','.join(f'0x{v:016X}' for v in values[index:index+3])
        source += (',' if index+3<len(values) else '')+'\n'
    source += '''};
Bool TrigMatches(U64 actual,U64 expected)
{
  if((expected&0x7FFFFFFFFFFFFFFF)>=0x7FF0000000000000 || !(expected&0x7FFFFFFFFFFFFFFF))
    return actual==expected;
  if((actual^expected)>>63)return FALSE;
  if(actual>expected)return actual-expected<=1;
  return expected-actual<=1;
}
I64 Main(I64 a,I64 b)
{
  I64 i;
  F64 result;
  for(i=0;i<1024;i++) {
    result=I386TrigSin(trig_vectors[i*3](F64));
    if(!TrigMatches(result(U64),trig_vectors[i*3+1]))return i*2+1;
    result=I386TrigCos(trig_vectors[i*3](F64));
    if(!TrigMatches(result(U64),trig_vectors[i*3+2]))return i*2+2;
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
    target = ROOT/'tests/guest/i386-soft-f64-trig/Target.HC'
    expected = generate()
    if args.check:
        if target.read_text() != expected:
            raise SystemExit('Regenerate independent Sin/Cos fixture')
        print('Verified 1024 independent native Sin/Cos vectors')
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(expected)
