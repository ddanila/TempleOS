#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
U64 f64_oracle[2048];
I64 Main(I64 a,I64 b)
{
  I64 i;
  for (i=0;i<1024;i++)
    if (I386F64ToI64(f64_oracle[i*2])!=f64_oracle[i*2+1]) return i+1;
  return 0;
}
#include "/Kernel/I386/SoftF64.HC"
