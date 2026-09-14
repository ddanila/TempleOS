#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
#include "/Kernel/I386/Float.HH"
U64 f64_oracle[3072];
I64 Main(I64 a,I64 b)
{
  I64 i;
  F64 value;
  for (i=0;i<1024;i++) {
    value=ToF64(f64_oracle[i*3]);
    if (value(U64)!=f64_oracle[i*3+2]) return i*3+3;
    if (I386F64FromU64(f64_oracle[i*3])!=f64_oracle[i*3+1]) return i*3+1;
    if (I386F64FromI64(f64_oracle[i*3])!=f64_oracle[i*3+2]) return i*3+2;
  }
  return 0;
}
#include "/Kernel/I386/SoftF64.HC"
