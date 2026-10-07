#include "/Kernel/I386/SoftF64.HH"
#include "/Kernel/I386/FloatMath.HH"
F64 Round(F64 value)
{
  U64 result=I386F64Round(value(U64));
  return result(F64);
}
F64 Trunc(F64 value)
{
  U64 result=I386F64Trunc(value(U64));
  return result(F64);
}
F64 Floor(F64 value)
{
  U64 result=I386F64Floor(value(U64));
  return result(F64);
}
F64 Ceil(F64 value)
{
  U64 result=I386F64Ceil(value(U64));
  return result(F64);
}

#include "/Kernel/I386/Pow10.HC"
#include "/Kernel/I386/FloatLog.HC"

#include "/Kernel/I386/FloatTrig.HC"
F64 Sin(F64 value) { return I386TrigSin(value); }
F64 Cos(F64 value) { return I386TrigCos(value); }

#include "/Kernel/I386/FloatPolar.HC"
F64 Arg(F64 x,F64 y) { return I386PolarArg(x,y); }
