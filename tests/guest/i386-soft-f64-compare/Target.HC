#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
U64 f64_oracle[3072];
I64 Main(I64 a,I64 b)
{
  I64 i,result,reverse,expected;
  for (i=0;i<1024;i++) {
    result=I386F64Compare(f64_oracle[i*3],f64_oracle[i*3+1]);
    expected=f64_oracle[i*3+2];
    if (result!=expected) return i*2+1;
    reverse=I386F64Compare(f64_oracle[i*3+1],f64_oracle[i*3]);
    if (expected!=I386_F64_UNORDERED) expected=-expected;
    if (reverse!=expected) return i*2+2;
  }
  return 0;
}
#include "/Kernel/I386/SoftF64.HC"
