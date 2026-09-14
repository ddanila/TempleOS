#include "/Kernel/I386/SoftF64.HH"

U64 I386F64Abs(U64 value)
{
  value&=0x7FFFFFFFFFFFFFFF;
  if (value>0x7FF0000000000000) value|=0x0008000000000000;
  return value;
}

//Round a binary64 value to an integral binary64 without narrowing to I64.
//Modes: nearest/even, toward -infinity, toward +infinity, toward zero.
U64 I386F64Integral(U64 value,I64 mode)
{
  U64 magnitude=value&0x7FFFFFFFFFFFFFFF,unit,fraction,result;
  I64 exp=(magnitude>>52)-1023;
  Bool negative=(value>>63)!=0,increment=FALSE;
  if (magnitude>0x7FF0000000000000) return value|0x0008000000000000;
  if (!magnitude || exp>=52) return value;
  if (exp<0) {
    result=value&0x8000000000000000;
    if (mode==1 && negative || mode==2 && !negative ||
        mode==0 && magnitude>0x3FE0000000000000)
      result|=0x3FF0000000000000;
    return result;
  }
  unit=1(U64)<<(52-exp);
  fraction=value&(unit-1);
  result=value&~(unit-1);
  if (fraction) {
    if (mode==1 && negative || mode==2 && !negative) increment=TRUE;
    if (mode==0 && (fraction>unit>>1 ||
        fraction==unit>>1 && (result&unit))) increment=TRUE;
    if (increment) result+=unit;
  }
  return result;
}
U64 I386F64Round(U64 value) { return I386F64Integral(value,0); }
U64 I386F64Floor(U64 value) { return I386F64Integral(value,1); }
U64 I386F64Ceil(U64 value) { return I386F64Integral(value,2); }
U64 I386F64Trunc(U64 value) { return I386F64Integral(value,3); }

extern U64 I386F64RoundPack(U64 sign,I64 exp,U64 x);

U64 I386F64Sqrt(U64 value)
{
  U64 magnitude=value&0x7FFFFFFFFFFFFFFF,x,high,low,root=0,remainder=0,trial;
  I64 exp,i;
  if (magnitude>0x7FF0000000000000) return value|0x0008000000000000;
  if (!magnitude) return value; //Preserve both zeros.
  if (value>>63) return 0xFFF8000000000000; //x64 indefinite for negative operands.
  if (magnitude==0x7FF0000000000000) return value;
  exp=value>>52; x=value&0x000FFFFFFFFFFFFF;
  if (exp) x|=0x0010000000000000;
  else {
    exp=1;
    while (x<0x0010000000000000) { x<<=1; exp--; }
  }
  exp-=1023;
  if (exp&1) { x<<=1; exp--; }
  //sqrt(x*2^58) gives 53 significand bits plus three rounding bits.
  //Feed the 112-bit radicand two bits at a time through a 64-bit remainder.
  high=x>>6; low=x<<58;
  for (i=0;i<64;i++) {
    remainder=(remainder<<2)|(high>>62);
    high=(high<<2)|(low>>62); low<<=2;
    trial=(root<<2)|1; root<<=1;
    if (remainder>=trial) { remainder-=trial; root|=1; }
  }
  if (remainder) root|=1;
  return I386F64RoundPack(0,(exp>>1)+1023,root);
}

U64 I386F64ShiftJam(U64 value,I64 distance)
{
  if (!distance) return value;
  if (distance>=64) return value!=0;
  return (value>>distance)|((value<<(64-distance))!=0);
}

//x has a hidden bit at 55 plus guard/round/sticky bits.
U64 I386F64RoundPack(U64 sign,I64 exp,U64 x)
{
  U64 sig,round;
  if (exp<1) { x=I386F64ShiftJam(x,1-exp); exp=1; }
  sig=x>>3; round=x&7;
  if (round>4 || (round==4 && (sig&1))) sig++;
  if (sig&0x0020000000000000) { sig>>=1; exp++; }
  if (exp>=0x7FF) return sign|0x7FF0000000000000;
  if (exp==1 && sig<0x0010000000000000) exp=0;
  return sign|(exp(U64)<<52)|(sig&0x000FFFFFFFFFFFFF);
}

U64 I386F64AddSub(U64 a,U64 b,Bool subtract)
{
  U64 magnitude=0x7FFFFFFFFFFFFFFF,frac=0x000FFFFFFFFFFFFF;
  U64 infinity=0x7FF0000000000000,quiet=0x0008000000000000;
  U64 sign,x,y,t;
  I64 exp,other;
  //Quiet the first NaN before subtraction can change its sign.
  if ((a&magnitude)>infinity) return a|quiet;
  if ((b&magnitude)>infinity) return b|quiet;
  if (subtract) b^=0x8000000000000000;
  if ((a&magnitude)==infinity) {
    if ((b&magnitude)==infinity && ((a^b)>>63)) return infinity|quiet;
    return a;
  }
  if ((b&magnitude)==infinity) return b;
  if ((a&magnitude)<(b&magnitude)) { t=a; a=b; b=t; }
  sign=a&0x8000000000000000;
  exp=(a>>52)&0x7FF; other=(b>>52)&0x7FF;
  x=a&frac; y=b&frac;
  if (exp) x|=0x0010000000000000;
  else exp=1;
  if (other) y|=0x0010000000000000;
  else other=1;
  x<<=3; y=I386F64ShiftJam(y<<3,exp-other);
  if (!((a^b)>>63)) {
    x+=y;
    if (x&0x0100000000000000) { x=I386F64ShiftJam(x,1); exp++; }
  } else {
    x-=y;
    if (!x) return 0;
    while (exp>1 && x<0x0080000000000000) { x<<=1; exp--; }
  }
  return I386F64RoundPack(sign,exp,x);
}

public U64 I386F64Add(U64 a,U64 b) { return I386F64AddSub(a,b,FALSE); }
public U64 I386F64Sub(U64 a,U64 b) { return I386F64AddSub(a,b,TRUE); }


public U64 I386F64Mul(U64 a,U64 b)
{
  U64 magnitude=0x7FFFFFFFFFFFFFFF,infinity=0x7FF0000000000000;
  U64 quiet=0x0008000000000000,frac=0x000FFFFFFFFFFFFF;
  U64 sign=(a^b)&0x8000000000000000,x,y,low,middle,high;
  I64 exp,other;
  if ((a&magnitude)>infinity) return a|quiet;
  if ((b&magnitude)>infinity) return b|quiet;
  a&=magnitude; b&=magnitude;
  if (a==infinity || b==infinity) {
    if (!a || !b) return infinity|quiet;
    return sign|infinity;
  }
  if (!a || !b) return sign;
  exp=a>>52; other=b>>52;
  x=a&frac; y=b&frac;
  if (exp) x|=0x0010000000000000;
  else {
    exp=1;
    while (x<0x0010000000000000) { x<<=1; exp--; }
  }
  if (other) y|=0x0010000000000000;
  else {
    other=1;
    while (y<0x0010000000000000) { y<<=1; other--; }
  }
  exp+=other-1023;
  //Exact 53x53 product in two words. Cross terms fit in 54 bits.
  low=(x&0xFFFFFFFF)*(y&0xFFFFFFFF);
  middle=(x>>32)*(y&0xFFFFFFFF)+(x&0xFFFFFFFF)*(y>>32)+(low>>32);
  high=(x>>32)*(y>>32)+(middle>>32);
  low=(low&0xFFFFFFFF)|(middle<<32);
  x=(high<<15)|(low>>49)|((low<<15)!=0);
  if (x&0x0100000000000000) { x=I386F64ShiftJam(x,1); exp++; }
  return I386F64RoundPack(sign,exp,x);
}

public U64 I386F64Div(U64 a,U64 b)
{
  U64 magnitude=0x7FFFFFFFFFFFFFFF,infinity=0x7FF0000000000000;
  U64 quiet=0x0008000000000000,frac=0x000FFFFFFFFFFFFF;
  U64 sign=(a^b)&0x8000000000000000,x,y,quotient=0;
  I64 exp,other,i;
  if ((a&magnitude)>infinity) return a|quiet;
  if ((b&magnitude)>infinity) return b|quiet;
  a&=magnitude; b&=magnitude;
  if ((!a && !b) || (a==infinity && b==infinity)) return infinity|quiet;
  if (a==infinity || !b) return sign|infinity;
  if (!a || b==infinity) return sign;
  exp=a>>52; other=b>>52;
  x=a&frac; y=b&frac;
  if (exp) x|=0x0010000000000000;
  else {
    exp=1;
    while (x<0x0010000000000000) { x<<=1; exp--; }
  }
  if (other) y|=0x0010000000000000;
  else {
    other=1;
    while (y<0x0010000000000000) { y<<=1; other--; }
  }
  exp-=other-1023;
  if (x<y) { x<<=1; exp--; }
  //One integer bit and 55 fractional bits; the remainder supplies sticky.
  //Each shifted remainder fits in 54 bits, including subnormal operands.
  for (i=0;i<56;i++) {
    quotient<<=1;
    if (x>=y) { x-=y; quotient|=1; }
    x<<=1;
  }
  if (x) quotient|=1;
  return I386F64RoundPack(sign,exp,quotient);
}

public U64 I386F64FromU64(U64 value)
{
  I64 exp=1078; //Exponent bias plus the guard-extended hidden-bit position.
  if (!value) return 0;
  while (value>=0x0100000000000000) {
    value=I386F64ShiftJam(value,1); exp++;
  }
  while (value<0x0080000000000000) { value<<=1; exp--; }
  return I386F64RoundPack(0,exp,value);
}

public U64 I386F64FromI64(I64 value)
{
  U64 magnitude=value;
  if (value<0) {
    //Unsigned subtraction also handles I64_MIN without signed overflow.
    magnitude=0-magnitude;
    return 0x8000000000000000|I386F64FromU64(magnitude);
  }
  return I386F64FromU64(magnitude);
}

public I64 I386F64Compare(U64 a,U64 b)
{
  U64 magnitude=0x7FFFFFFFFFFFFFFF,infinity=0x7FF0000000000000;
  if ((a&magnitude)>infinity || (b&magnitude)>infinity) return I386_F64_UNORDERED;
  if (a==b || !((a|b)&magnitude)) return 0;
  if ((a^b)>>63) {
    if (a>>63) return -1;
    return 1;
  }
  if (a>>63) {
    if (a>b) return -1;
  } else if (a<b) return -1;
  return 1;
}

public I64 I386F64ToI64(U64 value)
{
  I64 exp=((value>>52)&0x7FF)-1023;
  U64 magnitude;
  //Match masked x64 FISTTP: truncate, returning integer indefinite if invalid.
  if (exp<0) return 0;
  if (exp>=63) return 0x8000000000000000;
  magnitude=(value&0x000FFFFFFFFFFFFF)|0x0010000000000000;
  if (exp<52) magnitude>>=52-exp;
  else magnitude<<=exp-52;
  if (value>>63) magnitude=0-magnitude;
  return magnitude;
}
