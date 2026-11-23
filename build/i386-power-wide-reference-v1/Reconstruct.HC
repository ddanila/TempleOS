//Evaluate exp(fraction*ln(2)) with 126 fractional bits, then truncate once
//when packing the scaled binary64 result.
U0 PowerMultiplyFixed(U32 *result,U32 *left,U32 *right)
{
  U32 product[8];
  I64 i;
  PowerMultiplyWords(product,left,4,right,4);
  for (i=0;i<4;i++)
    result[i]=(product[i+3]>>30)|(product[i+4]<<2);
}

F64 PowerWideReconstruct(F64 reduced)
{
  U64 bits=reduced(U64),magnitude=bits&0x7FFFFFFFFFFFFFFF,
      fraction_bits,significand,limb,carry;
  U32 ln2[4];
  U32 fraction[4],argument[4],term[4],sum[6];
  I64 whole,shift,i,n;
  Bool negative;
  if (magnitude>0x7FF0000000000000)
    return (bits|0x0008000000000000)(F64);
  if (magnitude==0x7FF0000000000000)
    return 0xFFF8000000000000(F64);
  if (reduced>=1024.0) return 0x7FEFFFFFFFFFFFFF(F64);
  if (reduced<=-1075.0) return 0.0;

  whole=ToI64(reduced);
  fraction_bits=(reduced-ToF64(whole))(U64);
  negative=fraction_bits>>63;
  fraction_bits&=0x7FFFFFFFFFFFFFFF;
  for (i=0;i<6;i++) sum[i]=0;
  for (i=0;i<4;i++) fraction[i]=0;
  term[0]=0; term[1]=0; term[2]=0; term[3]=0x40000000;
  sum[3]=term[3];

  shift=((fraction_bits>>52)&0x7FF)-949;
  if (shift<=-53) {
    if (fraction_bits && negative) {
      sum[0]=0xFFFFFFFF; sum[1]=0xFFFFFFFF; sum[2]=0xFFFFFFFF;
      sum[3]--;
    }
    return PowerPackWords(sum,whole-126,0)(F64);
  }
  significand=(fraction_bits&0x000FFFFFFFFFFFFF)|0x0010000000000000;
  if (shift<0) {
    significand>>=-shift;
    shift=0;
  }
  for (i=shift>>5;i<4;i++) {
    fraction[i]=significand<<(shift&31);
    significand>>=32-(shift&31);
    shift&=~31;
  }
  ln2[0]=0x00FCBDAB; ln2[1]=0xF278ECE6;
  ln2[2]=0xF473DE6A; ln2[3]=0x2C5C85FD;
  PowerMultiplyFixed(argument,fraction,ln2);
  if (negative && !(argument[0]|argument[1]|argument[2]|argument[3])) {
    sum[0]=0xFFFFFFFF; sum[1]=0xFFFFFFFF; sum[2]=0xFFFFFFFF;
    sum[3]--;
  }
  for (n=1;n<=40;n++) {
    PowerMultiplyFixed(term,term,argument);
    carry=0;
    for (i=3;i>=0;i--) {
      limb=term[i];
      limb|=carry<<32;
      term[i]=limb/n;
      carry=limb%n;
    }
    if (!(term[0]|term[1]|term[2]|term[3])) break;
    carry=0;
    for (i=0;i<4;i++) {
      limb=sum[i];
      if (negative && n&1) {
        limb-=term[i]+carry;
        carry=limb>>63;
      } else {
        limb+=term[i]+carry;
        carry=limb>>32;
      }
      sum[i]=limb;
    }
  }
  return PowerPackWords(sum,whole-126,0)(F64);
}
