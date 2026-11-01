/*
 * Copyright (C) 2004 by Sun Microsystems, Inc. All rights reserved.
 * Permission to use, copy, modify, and distribute this software is freely
 * granted, provided that this notice is preserved.
 */
//Adapted from fdlibm e_exp.c. The original x87 provider truncates and has
//different finite rounding; explicit infinity and saturation handling preserves
//its observed exceptional-result policy. No FPU or exception flags are used.
F64 Exp(F64 x)
{
  U64 bits=x(U64),magnitude=bits&0x7FFFFFFFFFFFFFFF,ybits;
  I64 hx=magnitude>>32,negative=bits>>63,k=0;
  F64 y,hi=0,lo=0,c,t,
    ln2hi=0x3FE62E42FEE00000(F64),ln2lo=0x3DEA39EF35793C76(F64),
    p1=0x3FC555555555553E(F64),p2=0xBF66C16C16BEBD93(F64),
    p3=0x3F11566AAF25DE2C(F64),p4=0xBEBBBD41C5D26BF1(F64),
    p5=0x3E66376972BEA4D0(F64);
  if(magnitude>0x7FF0000000000000) {
    bits|=0x0008000000000000;return bits(F64);
  }
  if(magnitude==0x7FF0000000000000)return 0xFFF8000000000000(F64);
  if(x>0x40862E42FEFA39EF(F64))return 0x7FEFFFFFFFFFFFFF(F64);
  if(x<0xC0874385446D71C3(F64))return 0.0;
  if(hx>0x3FD62E42) {
    if(hx<0x3FF0A2B2) {
      if(negative) { hi=x+ln2hi;lo=-ln2lo;k=-1; }
      else { hi=x-ln2hi;lo=ln2lo;k=1; }
    } else {
      if(negative)k=ToI64(0x3FF71547652B82FE(F64)*x-0.5);
      else k=ToI64(0x3FF71547652B82FE(F64)*x+0.5);
      t=ToF64(k);hi=x-t*ln2hi;lo=t*ln2lo;
    }
    x=hi-lo;
  } else if(hx<0x3E300000) return 1.0+x;
  t=x*x;c=x-t*(p1+t*(p2+t*(p3+t*(p4+t*p5))));
  if(!k)return 1.0-((x*c)/(c-2.0)-x);
  y=1.0-((lo-(x*c)/(2.0-c))-hi);
  if(k>=-1021) {
    ybits=y(U64)+k*0x0010000000000000;
    return ybits(F64);
  }
  ybits=y(U64)+(k+1000)*0x0010000000000000;
  return ybits(F64)*0x0170000000000000(F64);
}
