#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Math.HH"
U64 math_oracle[12288];
I64 Main(I64 unused_a,I64 unused_b)
{
  I64 i,count;
  U64 *row,value,quotient,remainder,parts[2];
  U8 digits[20],*expected="51615590737044764481";
  for (i=0;i<1024;i++) {
    row=math_oracle+i*12;
    if (AbsI64(row[0])!=row[2]) return i*10+1;
    if (SignI64(row[0])!=row[3]) return i*10+2;
    if (MinI64(row[0],row[1])!=row[4]) return i*10+3;
    if (MaxI64(row[0],row[1])!=row[5]) return i*10+4;
    if (MinU64(row[0],row[1])!=row[6]) return i*10+5;
    if (MaxU64(row[0],row[1])!=row[7]) return i*10+6;
    if (SqrI64(row[0])!=row[8]) return i*10+7;
    if (SqrU64(row[0])!=row[9]) return i*10+8;
    if (row[1]) {
      quotient=row[0]; remainder=ModU64(&quotient,row[1]);
      if (quotient!=row[10]) return i*10+9;
      if (remainder!=row[11]) return i*10+10;
    }
  }
  count=-3; value=AbsI64(count++);
  if (value!=3 || count!=-2) return 10241;
  count=0; value=MinI64(count++,count++);
  if (value!=0 || count!=2) return 10242;
  count=-3; value=MaxI64(AbsI64(count),SqrI64(count));
  if (value!=9 || count!=-3) return 10243;
  quotient=0xFFFFFFFFFFFFFFFF; count=0;
  do digits[count++]=ModU64(&quotient,10)+'0'; while (quotient);
  if (count!=20) return 10244;
  for (i=0;i<20;i++) if (digits[i]!=expected[i]) return 10245;
  quotient=25; remainder=ModU64(&quotient,quotient);
  if (quotient!=1 || remainder) return 10246;
  parts[0]=99; parts[1]=0x123456789ABCDEF0; count=0;
  remainder=ModU64(&parts[count++],10);
  if (count!=1 || parts[0]!=9 || remainder!=9 || parts[1]!=0x123456789ABCDEF0)
    return 10247;
  quotient=123; remainder=ModU64(&quotient,ModU64(&quotient,10)+1);
  if (quotient!=3 || remainder) return 10248;
  return 0;
}
