#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
U64 f64_oracle[10240];
I64 Main(I64 a,I64 b)
{
  I64 i;
  for (i=0;i<2048;i++) {
    if (I386F64Add(f64_oracle[i*5],f64_oracle[i*5+1])!=f64_oracle[i*5+2]) return i*3+1;
    if (I386F64Sub(f64_oracle[i*5],f64_oracle[i*5+1])!=f64_oracle[i*5+3]) return i*3+2;
    if (I386F64Mul(f64_oracle[i*5],f64_oracle[i*5+1])!=f64_oracle[i*5+4]) return i*3+3;
  }
  return 0;
}
#include "/Kernel/I386/SoftF64.HC"
