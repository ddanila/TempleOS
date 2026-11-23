F64 PowerWide(F64 base,F64 exponent)
{
  U64 base_bits=base(U64),exponent_bits=exponent(U64),
      a=base_bits&0x7FFFFFFFFFFFFFFF,b=exponent_bits&0x7FFFFFFFFFFFFFFF,
      infinity=0x7FF0000000000000,quiet=0x0008000000000000;
  F64 result;
  if (!exponent_bits) return 1.0;
  if (!base_bits) return 0.0;
  if (a>infinity) result=(a|quiet)(F64);
  else if (b>infinity) result=(exponent_bits|quiet)(F64);
  else if (!a || a==infinity || b==infinity)
    result=0xFFF8000000000000(F64);
  else
    result=PowerWideReconstruct(PowerWideReduced(base,exponent));

  // The original tests the low bit of FISTTP's signed 64-bit result.
  // Invalid conversions produce the even indefinite integer.
  if (base_bits>>63 && exponent<0x43E0000000000000(F64) &&
      exponent>=0xC3E0000000000000(F64) && ToI64(exponent)&1)
    result=-result;
  return result;
}
