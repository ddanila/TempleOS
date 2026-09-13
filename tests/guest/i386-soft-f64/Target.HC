#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
U64 f64_oracle[12288];
I64 Main(I64 a,I64 b)
{
  I64 i;
  for (i=0;i<2048;i++) {
    if (I386F64Add(f64_oracle[i*6],f64_oracle[i*6+1])!=f64_oracle[i*6+2]) return i*4+1;
    if (I386F64Sub(f64_oracle[i*6],f64_oracle[i*6+1])!=f64_oracle[i*6+3]) return i*4+2;
    if (I386F64Mul(f64_oracle[i*6],f64_oracle[i*6+1])!=f64_oracle[i*6+4]) return i*4+3;
    if (I386F64Div(f64_oracle[i*6],f64_oracle[i*6+1])!=f64_oracle[i*6+5]) return i*4+4;
  }
  return 0;
}
#include "/Kernel/I386/SoftF64.HC"
