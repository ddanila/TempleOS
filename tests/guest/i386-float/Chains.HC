I64 chain_float_branch_differences,chain_mixed_middle_differences;
I64 ChainInteger(I64 a,I64 b,I64 c,I64 d)
{
  return a<b<=c<d;
}
I64 ChainIntegerBranch(I64 a,I64 b,I64 c,I64 d)
{
  if (a<b<=c<d) return 1;
  return 0;
}
I64 ChainUnsigned(U64 a,U64 b,U64 c)
{
  return a<=b<c;
}
I64 ChainMixed(I64 a,F64 b,I64 c)
{
  return a<b<c;
}
I64 ChainMixedMiddle(F64 a,I64 b,F64 c)
{
  return a<b<c;
}
I64 ChainFloat(F64 a,F64 b,F64 c)
{
  return a<b<=c;
}
I64 ChainFloatBranch(F64 a,F64 b,F64 c)
{
  if (a<b<=c) return 1;
  return 0;
}
I64 ChainPick(I64 value,I64 *count)
{
  (*count)++;
  return value;
}
I64 ChainEffects(I64 a,I64 b,I64 c,I64 d)
{
  I64 count=0,result,expected=2;
  result=ChainPick(a,&count)<ChainPick(b,&count)<=
    ChainPick(c,&count)<ChainPick(d,&count);
  if (count!=4) return 1;
  count=0;
  if (ChainPick(a,&count)<ChainPick(b,&count)<=
      ChainPick(c,&count)<ChainPick(d,&count)) result=1;
  if (a<b) { expected++; if (b<=c) expected++; }
  if (count!=expected) return 2;
  return 0;
}
I64 CheckChains(Bool native)
{
  I64 integers[8],i,j,k,expected;
  chain_float_branch_differences=chain_mixed_middle_differences=0;
  U64 floats[8];
  F64 a,b,c;
  integers[0]=0x8000000000000000; integers[1]=-0x100000001;
  integers[2]=-1; integers[3]=0; integers[4]=1;
  integers[5]=0x100000000; integers[6]=0x100000001;
  integers[7]=0x7FFFFFFFFFFFFFFF;
  floats[0]=0; floats[1]=0x8000000000000000;
  floats[2]=1; floats[3]=0xBFF0000000000000;
  floats[4]=0x3FF0000000000000; floats[5]=0x7FF0000000000000;
  floats[6]=0xFFF0000000000000; floats[7]=0x7FF8000000001234;
  for (i=0;i<8;i++) for (j=0;j<8;j++) for (k=0;k<8;k++) {
    expected=(integers[i]<integers[j]) && (integers[j]<=integers[k]) &&
      (integers[k]<integers[7]);
    if (ChainInteger(integers[i],integers[j],integers[k],integers[7])!=expected)
      return 1+i*64+j*8+k;
    if (ChainIntegerBranch(integers[i],integers[j],integers[k],integers[7])!=expected)
      return 513+i*64+j*8+k;
    if (ChainEffects(integers[i],integers[j],integers[k],integers[7]))
      return 1025+i*64+j*8+k;
    a=floats[i](F64); b=floats[j](F64); c=floats[k](F64);
    expected=(a<b) && (b<=c);
    if (ChainFloat(a,b,c)!=expected) return 1537+i*64+j*8+k;
    if (ChainFloatBranch(a,b,c)!=expected) {
      if (native || i!=7) return 2049+i*64+j*8+k;
      chain_float_branch_differences++;
    }
    expected=(integers[i](U64)<=integers[j](U64)) &&
      (integers[j](U64)<integers[k](U64));
    if (ChainUnsigned(integers[i],integers[j],integers[k])!=expected)
      return 2561+i*64+j*8+k;
    expected=(integers[i]<b) && (b<integers[k]);
    if (ChainMixed(integers[i],b,integers[k])!=expected)
      return 3073+i*64+j*8+k;
    expected=(a<integers[j]) && (integers[j]<c);
    if (ChainMixedMiddle(a,integers[j],c)!=expected) {
      if (native) return 3585+i*64+j*8+k;
      chain_mixed_middle_differences++;
    }
  }
  return 0;
}
