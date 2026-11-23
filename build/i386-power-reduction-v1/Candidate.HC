F64 PowerReconstruct(F64 reduced)
{
  U64 bits=reduced(U64),magnitude=bits&0x7FFFFFFFFFFFFFFF,scaled;
  I64 whole,exponent,shift;
  if (magnitude>0x7FF0000000000000)
    return (bits|0x0008000000000000)(F64);
  if (magnitude==0x7FF0000000000000)
    return 0xFFF8000000000000(F64);
  if (reduced>=1024.0) return 0x7FEFFFFFFFFFFFFF(F64);
  if (reduced<=-1075.0) return 0.0;

  whole=ToI64(reduced);
  scaled=I386ExpReduced((reduced-ToF64(whole))*0x3FE62E42FEFA39EF(F64))(U64);
  exponent=((scaled>>52)&0x7FF)+whole;
  if (exponent>=0x7FF) return 0x7FEFFFFFFFFFFFFF(F64);
  if (exponent>0)
    return ((scaled&0x000FFFFFFFFFFFFF)|(exponent(U64)<<52))(F64);
  shift=1-exponent;
  scaled=((scaled&0x000FFFFFFFFFFFFF)|0x0010000000000000)>>shift;
  return scaled(F64);
}

F64 PowerSoftware(F64 base,F64 exponent)
{
  F64 reduced,scaled;
  U8 line[96],*p;
  if (!exponent(U64)) return 1.0;
  if (!base(U64)) return 0.0;
  reduced=Log2(Abs(base))*exponent;
  StrPrint(line,"POWER native-reduced %016X\n",*(&reduced)(U64 *));
  p=line;
  while (*p) OutU8(0xE9,*p++);
  scaled=PowerReconstruct(reduced);
  if (base(U64)>>63 && ToI64(exponent)&1) scaled=-scaled;
  return scaled;
}
