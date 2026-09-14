#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
#include "/Kernel/I386/Float.HH"
#include "/Kernel/I386/FloatMath.HH"
U64 f64_oracle[8192];
I64 Main(I64 a,I64 b)
{
  I64 i;
  F64 value,old;
  for (i=0;i<1024;i++) {
    value=Abs(f64_oracle[i*8](F64));
    if (value(U64)!=f64_oracle[i*8+1]) return i*13+1;
    value=Sqr(f64_oracle[i*8](F64));
    if (value(U64)!=f64_oracle[i*8+2]) return i*13+2;
    if (I386F64Abs(f64_oracle[i*8])!=f64_oracle[i*8+1]) return i*13+3;
    value=Sqrt(f64_oracle[i*8](F64));
    if (value(U64)!=f64_oracle[i*8+3]) return i*13+4;
    if (I386F64Sqrt(f64_oracle[i*8])!=f64_oracle[i*8+3]) return i*13+5;
    value=Round(f64_oracle[i*8](F64));
    if (value(U64)!=f64_oracle[i*8+4]) return i*13+6;
    if (I386F64Round(f64_oracle[i*8])!=f64_oracle[i*8+4]) return i*13+7;
    value=Trunc(f64_oracle[i*8](F64));
    if (value(U64)!=f64_oracle[i*8+5]) return i*13+8;
    if (I386F64Trunc(f64_oracle[i*8])!=f64_oracle[i*8+5]) return i*13+9;
    value=Floor(f64_oracle[i*8](F64));
    if (value(U64)!=f64_oracle[i*8+6]) return i*13+10;
    if (I386F64Floor(f64_oracle[i*8])!=f64_oracle[i*8+6]) return i*13+11;
    value=Ceil(f64_oracle[i*8](F64));
    if (value(U64)!=f64_oracle[i*8+7]) return i*13+12;
    if (I386F64Ceil(f64_oracle[i*8])!=f64_oracle[i*8+7]) return i*13+13;
  }
  value=-1.5; value=Abs(Sqr(value));
  if (value(U64)!=0x4002000000000000) return 14001;
  i=-3; value=Sqr(i++);
  if (i!=-2 || value(U64)!=0x4022000000000000) return 14002;
  value=-1.5; old=Abs(value++);
  if (old(U64)!=0x3FF8000000000000 || value(U64)!=0xBFE0000000000000) return 14003;
  value=-1.5;
  if (ToI64(Abs(Sqr(value)))!=2) return 14004;
  value=-1.5; value=Sqrt(Sqr(value));
  if (value(U64)!=0x3FF8000000000000) return 14005;
  i=9; value=Sqrt(i++);
  if (value(U64)!=0x4008000000000000 || i!=10) return 14006;
  value=1.5; old=Round(value++);
  if (old(U64)!=0x4000000000000000 || value(U64)!=0x4004000000000000) return 14007;
  value=Floor(Ceil(-1.5))+Trunc(2.75);
  if (value(U64)!=0x3FF0000000000000) return 14008;
  i=3; value=Round(i++);
  if (value(U64)!=0x4008000000000000 || i!=4) return 14009;
  return 0;
}
#include "/Kernel/I386/SoftF64.HC"
#include "/Kernel/I386/FloatMath.HC"
