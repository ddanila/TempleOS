#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
#include "/Kernel/I386/Float.HH"
U64 f64_oracle[4096];
I64 Main(I64 a,I64 b)
{
  I64 i;
  F64 value,old;
  for (i=0;i<1024;i++) {
    value=Abs(f64_oracle[i*4](F64));
    if (value(U64)!=f64_oracle[i*4+1]) return i*5+1;
    value=Sqr(f64_oracle[i*4](F64));
    if (value(U64)!=f64_oracle[i*4+2]) return i*5+2;
    if (I386F64Abs(f64_oracle[i*4])!=f64_oracle[i*4+1]) return i*5+3;
    value=Sqrt(f64_oracle[i*4](F64));
    if (value(U64)!=f64_oracle[i*4+3]) return i*5+4;
    if (I386F64Sqrt(f64_oracle[i*4])!=f64_oracle[i*4+3]) return i*5+5;
  }
  value=-1.5; value=Abs(Sqr(value));
  if (value(U64)!=0x4002000000000000) return 5121;
  i=-3; value=Sqr(i++);
  if (i!=-2 || value(U64)!=0x4022000000000000) return 5122;
  value=-1.5; old=Abs(value++);
  if (old(U64)!=0x3FF8000000000000 || value(U64)!=0xBFE0000000000000) return 5123;
  value=-1.5;
  if (ToI64(Abs(Sqr(value)))!=2) return 5124;
  value=-1.5; value=Sqrt(Sqr(value));
  if (value(U64)!=0x3FF8000000000000) return 5125;
  i=9; value=Sqrt(i++);
  if (value(U64)!=0x4008000000000000 || i!=10) return 5126;
  return 0;
}
#include "/Kernel/I386/SoftF64.HC"
