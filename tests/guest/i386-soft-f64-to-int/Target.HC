#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
#include "/Kernel/I386/Float.HH"
#include "/Kernel/I386/Bool.HH"
U64 f64_oracle[2048];
I64 Main(I64 a,I64 b)
{
  I64 i;
  for (i=0;i<1024;i++) {
    if (ToBool(f64_oracle[i*2])!=(f64_oracle[i*2]!=0)) return i*4+4;
    if (ToBool(f64_oracle[i*2](F64))!=(f64_oracle[i*2+1]!=0)) return i*4+3;
    if (ToI64(f64_oracle[i*2](F64))!=f64_oracle[i*2+1]) return i*4+2;
    if (I386F64ToI64(f64_oracle[i*2])!=f64_oracle[i*2+1]) return i*4+1;
  }
  return 0;
}
#include "/Kernel/I386/SoftF64.HC"
