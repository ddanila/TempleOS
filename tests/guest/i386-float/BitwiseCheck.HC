U0 IntegerBitwiseValues(U64 a,U64 b,Bool unsigned_left,U64 *values)
{
  values[0]=a&b; values[1]=a|b; values[2]=a^b; values[3]=a<<b;
  if(unsigned_left) values[4]=a>>b;
  else values[4]=a(I64)>>b(I64);
}
I64 CheckMixedBitwisePair(U64 raw,U64 bits)
{
  U64 values[26],expected[26],converted=I386F64FromI64(raw(I64));
  U64 integer=I386F64ToI64(bits);
  I64 i;
  IntegerBitwiseValues(converted,bits,FALSE,expected);
  IntegerBitwiseValues(bits,converted,FALSE,expected+5);
  expected[10]=converted(I64)>>bits(I64);
  IntegerBitwiseValues(raw,integer,FALSE,expected+11);
  IntegerBitwiseValues(raw,integer,TRUE,expected+16);
  IntegerBitwiseValues(bits,raw,FALSE,expected+21);
  MixedBitwiseValues(raw,bits,values);
  for(i=0;i<26;i++) if(values[i]!=expected[i]) return i+1;
  return 0;
}
