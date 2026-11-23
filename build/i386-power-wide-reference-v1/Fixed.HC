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
  if (!a || a>=0x7FF0000000000000 || b>=0x7FF0000000000000)
    return Log2(Abs(base))*exponent;
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
