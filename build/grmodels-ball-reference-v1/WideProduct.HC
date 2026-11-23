// Model FMUL with 64 significand bits, followed by masked FISTTP to I64.
I64 BallWideMultiplyToI64(F64 left,F64 right)
{
  U64 a=left(U64),b=right(U64),negative=(a^b)>>63;
  U64 magnitude=0x7FFFFFFFFFFFFFFF,infinity=0x7FF0000000000000;
  U64 fraction=0x000FFFFFFFFFFFFF,implicit=0x0010000000000000;
  U64 x,y,low,middle,high,significand,remainder,half,result;
  I64 exp_a,exp_b,exponent,shift;

  a&=magnitude;
  b&=magnitude;
  if (a>=infinity || b>=infinity)
    return 0x8000000000000000;
  if (!a || !b)
    return 0;

  exp_a=a>>52;
  exp_b=b>>52;
  x=a&fraction;
  y=b&fraction;
  if (exp_a)
    x|=implicit;
  else {
    exp_a=1;
    while (x<implicit) {
      x<<=1;
      exp_a--;
    }
  }
  if (exp_b)
    y|=implicit;
  else {
    exp_b=1;
    while (y<implicit) {
      y<<=1;
      exp_b--;
    }
  }

  low=(x&0xFFFFFFFF)*(y&0xFFFFFFFF);
  middle=(x>>32)*(y&0xFFFFFFFF)+(x&0xFFFFFFFF)*(y>>32)+(low>>32);
  high=(x>>32)*(y>>32)+(middle>>32);
  low=(low&0xFFFFFFFF)|(middle<<32);

  shift=41+(high>>41);
  exponent=exp_a+exp_b-2046+(shift-41);
  significand=(high<<(64-shift))|(low>>shift);
  half=1(U64)<<(shift-1);
  remainder=low&((half<<1)-1);
  if (remainder>half || (remainder==half && significand&1)) {
    significand++;
    if (!significand) {
      significand=0x8000000000000000;
      exponent++;
    }
  }

  if (exponent<0)
    return 0;
  if (exponent>=63)
    return 0x8000000000000000;
  result=significand>>(63-exponent);
  if (negative)
    result=0-result;
  return result;
}
