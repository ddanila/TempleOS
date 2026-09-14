#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
#include "/Kernel/I386/Float.HH"
#include "/Kernel/I386/FloatMath.HH"
U64 f64_oracle[4096];
Bool LogMatches(U64 actual,U64 expected,I64 tolerance)
{
  if((expected&0x7FFFFFFFFFFFFFFF)>=0x7FF0000000000000 || !expected)
    return actual==expected;
  if((actual^expected)>>63) return FALSE;
  if(actual>expected) return actual-expected<=tolerance;
  return expected-actual<=tolerance;
}
I64 Main(I64 a,I64 b)
{
  I64 i;
  U64 bits;
  F64 value,old;
  for(i=0;i<1024;i++) {
    value=Ln(f64_oracle[i*4](F64));
    if(!LogMatches(value(U64),f64_oracle[i*4+1],1)) return i*3+1;
    value=Log10(f64_oracle[i*4](F64));
    if(!LogMatches(value(U64),f64_oracle[i*4+2],2)) return i*3+2;
    value=Log2(f64_oracle[i*4](F64));
    if(!LogMatches(value(U64),f64_oracle[i*4+3],2)) return i*3+3;
  }
  value=1.0; old=Ln(value++);
  if(old(U64) || value(U64)!=0x4000000000000000) return 5001;
  i=10; value=Log10(i++);
  if(value(U64)!=0x3FF0000000000000 || i!=11) return 5002;
  value=Ln(Pow10I64(0))+Log10(Pow10I64(2));
  if(value(U64)!=0x4000000000000000) return 5003;
  for(i=-308;i<=308;i++) {
    value=Floor(Log10(Pow10I64(i)));
    if(value!=ToF64(i)) return 4000+i+308;
  }
  for(i=-1074;i<=1023;i++) {
    if(i<-1022) bits=1(U64)<<(i+1074);
    else bits=(i+1023)(U64)<<52;
    value=Log2(bits(F64));
    if(value!=ToF64(i)) return 6000+i+1074;
  }
  value=2.0; old=Log2(value++);
  if(old(U64)!=0x3FF0000000000000 || value(U64)!=0x4008000000000000) return 5004;
  return 0;
}
#include "/Kernel/I386/SoftF64.HC"
#include "/Kernel/I386/FloatMath.HC"
