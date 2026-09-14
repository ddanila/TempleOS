I64 ConditionMask(F64 a,F64 b)
{
  I64 result=0;
  if (a) result|=1;
  if (!a) result|=2;
  if (a && b) result|=4;
  if (a || b) result|=8;
  if (a ^^ b) result|=16;
  return result;
}
I64 ConditionValues(F64 a,F64 b)
{
  return (!a)(I64)+2*(a && b)+4*(a || b)+8*(a ^^ b);
}
F64 ConditionPick(F64 value,I64 *calls)
{
  (*calls)++;
  return value;
}
I64 ConditionEffects(F64 a,F64 b)
{
  I64 calls=0,result;
  result=ConditionPick(a,&calls) && ConditionPick(b,&calls);
  if (calls!=2) return 1;
  calls=0;
  result=ConditionPick(a,&calls) || ConditionPick(b,&calls);
  if (calls!=2) return 2;
  calls=0;
  result=ConditionPick(a,&calls) ^^ ConditionPick(b,&calls);
  if (calls!=2) return 3;
  calls=0;
  if (ConditionPick(a,&calls) && ConditionPick(b,&calls)) result=1;
  if (calls!=1+(a(U64)!=0)) return 4;
  calls=0;
  if (ConditionPick(a,&calls) || ConditionPick(b,&calls)) result=1;
  if (calls!=1+(a(U64)==0)) return 5;
  calls=0;
  if (!(ConditionPick(a,&calls) &&
      (ConditionPick(b,&calls) || ConditionPick(a,&calls)))) result=1;
  result=1;
  if (a(U64)) { result=2; if (!b(U64)) result=3; }
  if (calls!=result) return 6;
  return 0;
}
I64 ConditionNotArithmetic(F64 a)
{
  return (!a)+2;
}
I64 ConditionLoops(F64 value)
{
  F64 a=value;
  I64 result=0,count=0;
  while (a) { result++; a=0.0; }
  for (a=value;a;a=0.0) result+=2;
  a=value;
  do { count++; if (count==2) a=0.0; } while (a);
  return result+4*count;
}
I64 CheckConditions()
{
  U64 values[12];
  I64 i,j,expected,truth_a,truth_b;
  values[0]=0; values[1]=0x8000000000000000;
  values[2]=1; values[3]=0x8000000000000001;
  values[4]=0x3FE0000000000000; values[5]=0xBFE0000000000000;
  values[6]=0x7FF0000000000000; values[7]=0xFFF0000000000000;
  values[8]=0x7FF8000000001234; values[9]=0xFFF0000000000001;
  values[10]=0x0000000100000000; values[11]=0x000FFFFFFFFFFFFF;
  for (i=0;i<12;i++) {
    expected=4; if (values[i]) expected=11;
    if (ConditionLoops(values[i](F64))!=expected) return 433+i;
  }
  for (i=0;i<12;i++) for (j=0;j<12;j++) {
    truth_a=values[i]!=0; truth_b=values[j]!=0;
    expected=truth_a+2*(!truth_a)+4*(truth_a && truth_b)+
      8*(truth_a || truth_b)+16*(truth_a ^^ truth_b);
    if (ConditionMask(values[i](F64),values[j](F64))!=expected)
      return 1+i*12+j;
    expected=(!truth_a)+2*(truth_a && truth_b)+4*(truth_a || truth_b)+
      8*(truth_a ^^ truth_b);
    if (ConditionValues(values[i](F64),values[j](F64))!=expected)
      return 145+i*12+j;
    if (ConditionEffects(values[i](F64),values[j](F64)))
      return 289+i*12+j;
  }
  return 0;
}
