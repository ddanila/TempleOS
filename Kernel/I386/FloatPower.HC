//Software power for the original HolyC rounding and sign rules.
//The logarithm uses 116 fractional bits and a 126-bit fixed-point mantissa.
U0 PowerMultiplyWords(U32 *product,U32 *left,I64 left_count,U32 *right,I64 right_count)
{
  I64 i,j;
  U64 sum,carry,limb;
  for (i=0;i<left_count+right_count;i++) product[i]=0;
  for (i=0;i<left_count;i++) {
    carry=0;
    limb=left[i];
    for (j=0;j<right_count;j++) {
      sum=limb*right[j]+product[i+j]+carry;
      product[i+j]=sum;
      carry=sum>>32;
    }
    product[i+right_count]=carry;
  }
}

I64 PowerLogWords(U64 base,U32 *result)
{
  U32 mantissa[4],square[8];
  U64 significand,shifted,carry,borrow;
  I64 exponent=(base>>52)&0x7FF,i,j,shift;
  significand=base&0x000FFFFFFFFFFFFF;
  if (exponent) {
    significand|=0x0010000000000000;
    exponent-=1023;
  } else {
    exponent=-1022;
    while (!(significand&0x0010000000000000)) {
      significand<<=1;
      exponent--;
    }
  }

  mantissa[0]=0; mantissa[1]=0;
  shifted=significand<<10;
  mantissa[2]=shifted; mantissa[3]=shifted>>32;
  for (i=0;i<4;i++) result[i]=0;
  for (i=0;i<116;i++) {
    PowerMultiplyWords(square,mantissa,4,mantissa,4);
    carry=(square[7]>>29)&1;
    shift=30+carry;
    for (j=0;j<4;j++)
      mantissa[j]=(square[j+3]>>shift)|(square[j+4]<<(32-shift));
    for (j=0;j<4;j++) {
      shifted=result[j];
      shifted=(shifted<<1)|carry;
      result[j]=shifted;
      carry=shifted>>32;
    }
  }
  if (exponent>=0)
    result[3]+=exponent<<20;
  else {
    borrow=0;
    for (i=0;i<4;i++) {
      shifted=0;
      if (i==3) shifted=(-exponent)<<20;
      shifted-=result[i]+borrow;
      result[i]=shifted;
      borrow=shifted>>63;
    }
  }
  return exponent;
}

U64 PowerPackWords(U32 *words,I64 scale,U64 sign)
{
  I64 high=191,exponent,bottom,i;
  U64 mantissa=0;
  while (high>=0 && !(words[high>>5]>>(high&31)&1)) high--;
  if (high<0) return sign;
  exponent=high+scale;
  if (exponent>1023) return sign|0x7FF0000000000000;
  if (exponent< -1074) return sign;
  bottom=high-52;
  if (exponent< -1022) bottom=-1074-scale;
  for (i=high;i>=bottom;i--) {
    mantissa<<=1;
    if (i>=0) mantissa|=words[i>>5]>>(i&31)&1;
  }
  if (exponent< -1022) return sign|mantissa;
  return sign|((exponent+1023)(U64)<<52)|(mantissa&0x000FFFFFFFFFFFFF);
}

F64 PowerWideReduced(F64 base,F64 exponent)
{
  U32 logarithm[4],exponent_words[2],product[6];
  U64 a=base(U64)&0x7FFFFFFFFFFFFFFF,b=exponent(U64)&0x7FFFFFFFFFFFFFFF,sign;
  U64 significand=b&0x000FFFFFFFFFFFFF;
  I64 scale=(b>>52)&0x7FF,k;
  k=PowerLogWords(a,logarithm);
  if (scale) {
    significand|=0x0010000000000000;
    scale-=1075;
  } else
    scale=-1074;
  exponent_words[0]=significand;
  exponent_words[1]=significand>>32;
  PowerMultiplyWords(product,logarithm,4,exponent_words,2);
  sign=exponent(U64)&0x8000000000000000;
  if (k<0) sign^=0x8000000000000000;
  return PowerPackWords(product,scale-116,sign)(F64);
}

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

U64 I386PowerImplementation(U64 base_bits,U64 exponent_bits)
{
  F64 base=base_bits(F64),exponent=exponent_bits(F64);
  U64 a=base_bits&0x7FFFFFFFFFFFFFFF,b=exponent_bits&0x7FFFFFFFFFFFFFFF,
      infinity=0x7FF0000000000000,quiet=0x0008000000000000;
  F64 result;
  if (!exponent_bits) return 0x3FF0000000000000;
  if (!base_bits) return 0;
  if (a>infinity) result=(a|quiet)(F64);
  else if (b>infinity) result=(exponent_bits|quiet)(F64);
  else if (!a || a==infinity || b==infinity)
    result=0xFFF8000000000000(F64);
  else
    result=PowerWideReconstruct(PowerWideReduced(base,exponent));

  // The original tests the low bit of FISTTP's signed 64-bit result.
  // Invalid conversions produce the even indefinite integer.
  if (base_bits>>63 && exponent<0x43E0000000000000(F64) &&
      exponent>=0xC3E0000000000000(F64) && ToI64(exponent)&1)
    result=-result;
  return result(U64);
}
