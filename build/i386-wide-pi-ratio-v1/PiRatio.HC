U64 PiRatioNormalize(U64 value,I64 *exponent)
{
  U64 mantissa=value&0x000FFFFFFFFFFFFF;
  I64 exp=(value>>52)&2047;
  if (exp) mantissa|=1(U64)<<52;
  else {
    exp=1;
    while (mantissa<1(U64)<<52) { mantissa<<=1; exp--; }
  }
  *exponent=exp-1023;
  return mantissa;
}

U64 PiRatioRoundExtended(U64 value,U64 remainder,U64 half,I64 *exponent)
{
  if (remainder>half || (remainder==half && (value&1))) {
    value++;
    if (!value) {
      value=1(U64)<<63;
      (*exponent)++;
    }
  }
  return value;
}

U64 PiRatioPack(U64 sign,I64 exp,U64 mantissa)
{
  U64 x=(mantissa>>8)|((mantissa&255)!=0),sig,round;
  exp+=1023;
  if (exp<1) {
    if (exp<=-63) x=x!=0;
    else x=(x>>(1-exp))|((x<<(63+exp))!=0);
    exp=1;
  }
  sig=x>>3; round=x&7;
  if (round>4 || (round==4 && (sig&1))) sig++;
  if (sig&0x0020000000000000) { sig>>=1; exp++; }
  if (exp>=0x7FF) return sign|0x7FF0000000000000;
  if (exp==1 && sig<0x0010000000000000) exp=0;
  return sign|(exp(U64)<<52)|(sig&0x000FFFFFFFFFFFFF);
}

U64 PiRatio(U64 numerator,U64 divisor)
{
  U64 sign=(numerator^divisor)&0x8000000000000000;
  U64 a=numerator&0x7FFFFFFFFFFFFFFF,b=divisor&0x7FFFFFFFFFFFFFFF;
  U64 infinity=0x7FF0000000000000,pi_significand=0xC90FDAA22168C235;
  U64 mantissa,denominator,low,middle,high,half,quotient;
  Bool carry;
  I64 exponent,divisor_exp,shift,i;
  if ((!a && !b) || (a==infinity && b==infinity))
    return 0xFFF8000000000000;
  if (a==infinity || !b) return sign|infinity;
  if (!a || b==infinity) return sign;
  mantissa=PiRatioNormalize(a,&exponent);
  denominator=PiRatioNormalize(b,&divisor_exp)<<11;

  //The product of a 53-bit significand and 64-bit pi fits in two words.
  low=(mantissa&0xFFFFFFFF)*(pi_significand&0xFFFFFFFF);
  middle=(mantissa>>32)*(pi_significand&0xFFFFFFFF)+
    (mantissa&0xFFFFFFFF)*(pi_significand>>32)+(low>>32);
  high=(mantissa>>32)*(pi_significand>>32)+(middle>>32);
  low=(low&0xFFFFFFFF)|(middle<<32);
  shift=52+(high>>52);
  exponent+=1+shift-52;
  half=1(U64)<<(shift-1);
  mantissa=(high<<(64-shift))|(low>>shift);
  mantissa=PiRatioRoundExtended(mantissa,low&((half<<1)-1),half,&exponent);

  exponent-=divisor_exp;
  if (mantissa<denominator) {
    mantissa=(mantissa<<1)-denominator;
    exponent--;
  } else
    mantissa-=denominator;
  quotient=1;
  for (i=0;i<63;i++) {
    carry=mantissa>>63;
    mantissa<<=1;
    quotient<<=1;
    if (carry || mantissa>=denominator) {
      mantissa-=denominator;
      quotient|=1;
    }
  }
  quotient=PiRatioRoundExtended(quotient,mantissa,denominator>>1,&exponent);
  return PiRatioPack(sign,exponent,quotient);
}
