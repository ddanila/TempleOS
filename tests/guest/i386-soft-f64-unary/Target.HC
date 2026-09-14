#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
#include "/Kernel/I386/Float.HH"
U64 f64_oracle[3072];
I64 Main(I64 a,I64 b)
{
  I64 i;
  F64 value,old;
  for (i=0;i<1024;i++) {
    value=Abs(f64_oracle[i*3](F64));
    if (value(U64)!=f64_oracle[i*3+1]) return i*3+1;
    value=Sqr(f64_oracle[i*3](F64));
    if (value(U64)!=f64_oracle[i*3+2]) return i*3+2;
    if (I386F64Abs(f64_oracle[i*3])!=f64_oracle[i*3+1]) return i*3+3;
  }
  value=-1.5; value=Abs(Sqr(value));
  if (value(U64)!=0x4002000000000000) return 3073;
  i=-3; value=Sqr(i++);
  if (i!=-2 || value(U64)!=0x4022000000000000) return 3074;
  value=-1.5; old=Abs(value++);
  if (old(U64)!=0x3FF8000000000000 || value(U64)!=0xBFE0000000000000) return 3075;
  value=-1.5;
  if (ToI64(Abs(Sqr(value)))!=2) return 3076;
  return 0;
}
#include "/Kernel/I386/SoftF64.HC"
