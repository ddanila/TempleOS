#include "/Kernel/I386/SoftF64.HH"

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
