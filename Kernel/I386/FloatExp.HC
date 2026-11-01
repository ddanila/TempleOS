/*
 * Copyright (C) 2004 by Sun Microsystems, Inc. All rights reserved.
 * Permission to use, copy, modify, and distribute this software is freely
 * granted, provided that this notice is preserved.
 */
//Adapted from fdlibm e_exp.c. The original x87 provider truncates and has
//different finite rounding; explicit infinity and saturation handling preserves
//its observed exceptional-result policy. No FPU or exception flags are used.
F64 I386ExpReduced(F64 x)
{//Input is the fractional binary exponent multiplied by ln(2), so |x|<ln(2).
  U64 magnitude=x(U64)&0x7FFFFFFFFFFFFFFF;
  I64 k=0;
  F64 y,hi=0,lo=0,c,t,
    ln2hi=0x3FE62E42FEE00000(F64),ln2lo=0x3DEA39EF35793C76(F64),
    p1=0x3FC555555555553E(F64),p2=0xBF66C16C16BEBD93(F64),
    p3=0x3F11566AAF25DE2C(F64),p4=0xBEBBBD41C5D26BF1(F64),
    p5=0x3E66376972BEA4D0(F64);
  if(magnitude>0x3FD62E4200000000) {
    if(x<0) {hi=x+ln2hi;lo=-ln2lo;k=-1;}
    else {hi=x-ln2hi;lo=ln2lo;k=1;}
    x=hi-lo;
  } else if(magnitude<0x3E30000000000000)return 1.0+x;
  t=x*x;c=x-t*(p1+t*(p2+t*(p3+t*(p4+t*p5))));
  if(!k)return 1.0-((x*c)/(c-2.0)-x);
  y=1.0-((lo-(x*c)/(2.0-c))-hi);
  if(k>0)return y*2.0;
  return y*0.5;
}

F64 Exp(F64 value)
{//Mirror the original x87 reduction: log2(e) is loaded and multiplied with
 //round-toward-zero, then stored as binary64 before the fractional F2XM1.
 U64 bits=value(U64),magnitude=bits&0x7FFFFFFFFFFFFFFF,
   sign=bits&0x8000000000000000,sig,low,middle,high,scaled,
   product_a,product_b;
 I64 exponent,n,shift;
 F64 reduced,fraction,result;
 if(magnitude>0x7FF0000000000000) {
   bits|=0x0008000000000000;return bits(F64);
 }
 if(magnitude==0x7FF0000000000000)return 0xFFF8000000000000(F64);
 if(!magnitude)return 1.0;
 if(magnitude<0x3BF0000000000000) {
   if(sign)return 0x3FEFFFFFFFFFFFFF(F64);
   return 1.0;
 }
 if(magnitude>=0x408F400000000000) {
   if(sign)return 0.0;
   return 0x7FEFFFFFFFFFFFFF(F64);
 }
 //The toward-zero x87 FLDL2E significand is 0xB8AA3B295C17F0BB.
 //Multiply the input's 53-bit significand by it in two 64-bit words.
 sig=(magnitude&0x000FFFFFFFFFFFFF)|0x0010000000000000;
 low=(sig&0xFFFFFFFF)*0x5C17F0BB;
 product_a=(sig>>32)*0x5C17F0BB;
 product_b=(sig&0xFFFFFFFF)*0xB8AA3B29;
 middle=(low>>32)+(product_a&0xFFFFFFFF)+(product_b&0xFFFFFFFF);
 high=(sig>>32)*0xB8AA3B29+(product_a>>32)+(product_b>>32)+(middle>>32);
 low=(low&0xFFFFFFFF)|(middle<<32);
 exponent=(magnitude>>52)&0x7FF;
 if(high&0x0010000000000000) exponent++;
 else high=(high<<1)|(low>>63);
 reduced=(sign|(exponent(U64)<<52)|(high&0x000FFFFFFFFFFFFF))(F64);
 n=ToI64(reduced);fraction=reduced-ToF64(n);
 result=I386ExpReduced(fraction*0x3FE62E42FEFA39EF(F64));
 scaled=result(U64);exponent=((scaled>>52)&0x7FF)+n;
 if(exponent>=0x7FF)return 0x7FEFFFFFFFFFFFFF(F64);
 if(exponent>0) {
   scaled=(scaled&0x000FFFFFFFFFFFFF)|(exponent(U64)<<52);
   return scaled(F64);
 }
 shift=1-exponent;
 if(shift>=64)return 0.0;
 scaled=((scaled&0x000FFFFFFFFFFFFF)|0x0010000000000000)>>shift;
 return scaled(F64);
}
