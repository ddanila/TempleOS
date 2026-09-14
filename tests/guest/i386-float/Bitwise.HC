//Binary forms operate on raw bits; compound forms first truncate the RHS.
U0 BitwiseValues(U64 a,U64 b,U64 *values)
{
  F64 left=a(F64),right=b(F64),result;
  result=left&right; values[0]=result(U64);
  result=left|right; values[1]=result(U64);
  result=left^right; values[2]=result(U64);
  result=left<<right; values[3]=result(U64);
  result=left>>right; values[4]=result(U64);
  result=(left&=right); values[5]=result(U64); values[10]=left(U64);
  left=a(F64); result=(left|=right); values[6]=result(U64); values[11]=left(U64);
  left=a(F64); result=(left^=right); values[7]=result(U64); values[12]=left(U64);
  left=a(F64); result=(left<<=right); values[8]=result(U64); values[13]=left(U64);
  left=a(F64); result=(left>>=right); values[9]=result(U64); values[14]=left(U64);
}
I64 CheckBitwisePair(U64 a,U64 b)
{
  U64 values[15],expected[10],right;
  I64 i,j;
  expected[0]=a&b; expected[1]=a|b; expected[2]=a^b;
  expected[3]=a<<b; expected[4]=a(I64)>>b(I64);
  right=ToI64(b(F64));
  expected[5]=a&right; expected[6]=a|right; expected[7]=a^right;
  expected[8]=a<<right; expected[9]=a(I64)>>right(I64);
  BitwiseValues(a,b,values);
  for(i=0;i<15;i++) { j=i; if(j>=10) j-=5; if(values[i]!=expected[j]) return i+1; }
  return 0;
}
