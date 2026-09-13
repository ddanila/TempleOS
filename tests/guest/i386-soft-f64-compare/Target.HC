#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
U64 f64_oracle[3072];
extern I64 Relations(F64 a,F64 b);
extern I64 Values(F64 a,F64 b,I64 divisor);
I64 Main(I64 a,I64 b)
{
  I64 i,result,reverse,expected,mask;
  for (i=0;i<1024;i++) {
    result=I386F64Compare(f64_oracle[i*3],f64_oracle[i*3+1]);
    expected=f64_oracle[i*3+2];
    if (result!=expected) return i*6+1;
    mask=2;
    if (expected==-1) mask=22;
    else if (!expected) mask=49;
    else if (expected==1) mask=42;
    if (Relations(f64_oracle[i*3](F64),f64_oracle[i*3+1](F64))!=mask) return i*6+2;
    if (Values(f64_oracle[i*3](F64),f64_oracle[i*3+1](F64),2)!=mask) return i*6+3;
    reverse=I386F64Compare(f64_oracle[i*3+1],f64_oracle[i*3]);
    if (expected!=I386_F64_UNORDERED) expected=-expected;
    if (reverse!=expected) return i*6+4;
    mask=2;
    if (expected==-1) mask=22;
    else if (!expected) mask=49;
    else if (expected==1) mask=42;
    if (Relations(f64_oracle[i*3+1](F64),f64_oracle[i*3](F64))!=mask) return i*6+5;
    if (Values(f64_oracle[i*3+1](F64),f64_oracle[i*3](F64),2)!=mask) return i*6+6;
  }
  return 0;
}
I64 Relations(F64 a,F64 b)
{
  I64 mask=0;
  if (a==b) mask|=1;
  if (a!=b) mask|=2;
  if (a<b) mask|=4;
  if (a>b) mask|=8;
  if (a<=b) mask|=16;
  if (a>=b) mask|=32;
  return mask;
}
I64 Values(F64 a,F64 b,I64 divisor)
{
  //A comparison result is an integer even though its operands were F64.
  return (a==b)+2*(a!=b)+4*(a<b)+8*(a>b)+16*(a<=b)+32*(a>=b)+64*((a==b)/divisor);
}
#include "/Kernel/I386/SoftF64.HC"
