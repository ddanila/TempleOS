#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
U64 f64_oracle[8192];
I64 Main(I64 a,I64 b)
{
  I64 i;
  for (i=0;i<2048;i++) {
    if (I386F64Add(f64_oracle[i*4],f64_oracle[i*4+1])!=f64_oracle[i*4+2]) return i*2+1;
    if (I386F64Sub(f64_oracle[i*4],f64_oracle[i*4+1])!=f64_oracle[i*4+3]) return i*2+2;
  }
  return 0;
}
#include "/Kernel/I386/SoftF64.HC"
