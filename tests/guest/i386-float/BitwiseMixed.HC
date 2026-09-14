U0 MixedBitwiseValues(U64 raw,U64 bits,U64 *values)
{
  I64 word=raw,stored;
  U64 wide=raw,stored_wide;
  F64 real=bits(F64),result,stored_real;
  result=word&real; values[0]=result(U64);
  result=word|real; values[1]=result(U64);
  result=word^real; values[2]=result(U64);
  result=word<<real; values[3]=result(U64);
  result=word>>real; values[4]=result(U64);
  result=real&word; values[5]=result(U64);
  result=real|word; values[6]=result(U64);
  result=real^word; values[7]=result(U64);
  result=real<<word; values[8]=result(U64);
  result=real>>word; values[9]=result(U64);
  result=wide>>real; values[10]=result(U64);
  stored=word; stored&=real; values[11]=stored;
  stored=word; stored|=real; values[12]=stored;
  stored=word; stored^=real; values[13]=stored;
  stored=word; stored<<=real; values[14]=stored;
  stored=word; stored>>=real; values[15]=stored;
  stored_wide=wide; stored_wide&=real; values[16]=stored_wide;
  stored_wide=wide; stored_wide|=real; values[17]=stored_wide;
  stored_wide=wide; stored_wide^=real; values[18]=stored_wide;
  stored_wide=wide; stored_wide<<=real; values[19]=stored_wide;
  stored_wide=wide; stored_wide>>=real; values[20]=stored_wide;
  stored_real=real; stored_real&=word; values[21]=stored_real(U64);
  stored_real=real; stored_real|=word; values[22]=stored_real(U64);
  stored_real=real; stored_real^=word; values[23]=stored_real(U64);
  stored_real=real; stored_real<<=word; values[24]=stored_real(U64);
  stored_real=real; stored_real>>=word; values[25]=stored_real(U64);
}
I64 bitwise_picks,bitwise_result;
F64 bitwise_cell;
I8 bitwise_byte;
U64 bitwise_wide;
F64 *BitwisePick() { bitwise_picks++; return &bitwise_cell; }
I8 *BitwisePickByte() { bitwise_picks++; return &bitwise_byte; }
U64 *BitwisePickWide() { bitwise_picks++; return &bitwise_wide; }
I64 CheckBitwiseDestinations(I64 expected_narrow)
{
  U64 raw=0x7FF0000000000001,mask=0xFFFFFFFFFFFFFFFF,wide;
  F64 result,right;
  I64 small;
  bitwise_picks=0; bitwise_cell=raw(F64);
  result=(*BitwisePick())^=mask;
  if(bitwise_picks!=1 || result(U64)!=0x800FFFFFFFFFFFFE ||
      bitwise_cell(U64)!=result(U64)) return 1;
  raw=0x8000000000000001; bitwise_cell=raw(F64); right=32.75;
  result=(*BitwisePick())>>=right;
  if(bitwise_picks!=2 || result(U64)!=0xFFFFFFFF80000000 ||
      bitwise_cell(U64)!=result(U64)) return 2;
  bitwise_byte=-127; right=254.5; small=(*BitwisePickByte())^=right;
  bitwise_result=small;
  if(bitwise_picks!=3 || small!=expected_narrow || bitwise_byte!=127) return 3;
  bitwise_wide=0xFFFFFFFFFFFFFFFF; right=31.75;
  wide=(*BitwisePickWide())>>=right;
  if(bitwise_picks!=4 || wide!=0x1FFFFFFFF || bitwise_wide!=wide) return 4;
  return 0;
}
