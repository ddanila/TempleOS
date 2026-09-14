#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Math.HH"
U64 math_oracle[10240];
I64 Main(I64 unused_a,I64 unused_b)
{
  I64 i,count;
  U64 *row,value;
  for (i=0;i<1024;i++) {
    row=math_oracle+i*10;
    if (AbsI64(row[0])!=row[2]) return i*8+1;
    if (SignI64(row[0])!=row[3]) return i*8+2;
    if (MinI64(row[0],row[1])!=row[4]) return i*8+3;
    if (MaxI64(row[0],row[1])!=row[5]) return i*8+4;
    if (MinU64(row[0],row[1])!=row[6]) return i*8+5;
    if (MaxU64(row[0],row[1])!=row[7]) return i*8+6;
    if (SqrI64(row[0])!=row[8]) return i*8+7;
    if (SqrU64(row[0])!=row[9]) return i*8+8;
  }
  count=-3; value=AbsI64(count++);
  if (value!=3 || count!=-2) return 8193;
  count=0; value=MinI64(count++,count++);
  if (value!=0 || count!=2) return 8194;
  count=-3; value=MaxI64(AbsI64(count),SqrI64(count));
  if (value!=9 || count!=-3) return 8195;
  return 0;
}
