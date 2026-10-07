/*
 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
 * Developed at SunSoft, a Sun Microsystems, Inc. business.
 * Permission to use, copy, modify, and distribute this software is freely
 * granted, provided that this notice is preserved.
 */
//HolyC adaptation of netlib.org/fdlibm/s_atan.c and e_atan2.c.
//Arg uses TempleOS ordering (x,y), rather than atan2 ordering (y,x).
F64 I386PolarATan(F64 x)
{
  U64 bits=x(U64),magnitude=bits&0x7FFFFFFFFFFFFFFF;
  I64 id=-1;
  F64 z,w,s1,s2,hi,lo;
  F64 a0=0x3FD555555555550D(F64),a1=0xBFC999999998EBC4(F64),
    a2=0x3FC24924920083FF(F64),a3=0xBFBC71C6FE231671(F64),
    a4=0x3FB745CDC54C206E(F64),a5=0xBFB3B0F2AF749A6D(F64),
    a6=0x3FB10D66A0D03D51(F64),a7=0xBFADDE2D52DEFD9A(F64),
    a8=0x3FA97B4B24760DEB(F64),a9=0xBFA2B4442C6A6C2F(F64),
    a10=0x3F90AD3AE322DA11(F64);
  if(magnitude>0x7FF0000000000000) {
    bits|=0x0008000000000000;return bits(F64);
  }
  if(magnitude>=0x4410000000000000) {
    bits=(bits&0x8000000000000000)|0x3FF921FB54442D18;return bits(F64);
  }
  if(magnitude<0x3FDC000000000000) {
    if(magnitude<0x3E20000000000000)return x;
  } else {
    x=magnitude(F64);
    if(magnitude<0x3FF3000000000000) {
      if(magnitude<0x3FE6000000000000) {
        id=0;x=(2*x-1)/(2+x);
        hi=0x3FDDAC670561BB4F(F64);lo=0x3C7A2B7F222F65E2(F64);
      } else {
        id=1;x=(x-1)/(x+1);
        hi=0x3FE921FB54442D18(F64);lo=0x3C81A62633145C07(F64);
      }
    } else if(magnitude<0x4003800000000000) {
      id=2;x=(x-1.5)/(1+1.5*x);
      hi=0x3FEF730BD281F69B(F64);lo=0x3C7007887AF0CBBD(F64);
    } else {
      id=3;x=-1.0/x;
      hi=0x3FF921FB54442D18(F64);lo=0x3C91A62633145C07(F64);
    }
  }
  z=x*x;w=z*z;
  s1=z*(a0+w*(a2+w*(a4+w*(a6+w*(a8+w*a10)))));
  s2=w*(a1+w*(a3+w*(a5+w*(a7+w*a9))));
  if(id<0)return x-x*(s1+s2);
  z=hi-((x*(s1+s2)-lo)-x);
  if(bits>>63)return -z;
  return z;
}
F64 I386PolarArg(F64 x,F64 y)
{
  U64 xb=x(U64),yb=y(U64),ax=xb&0x7FFFFFFFFFFFFFFF,
    ay=yb&0x7FFFFFFFFFFFFFFF,sign=yb&0x8000000000000000,result;
  I64 k;
  F64 z,polar_pi=0x400921FB54442D18(F64),pi_lo=0x3CA1A62633145C07(F64);
  //The NaN payload policy is explicit; original parity is a separate gate.
  if(ax>0x7FF0000000000000){xb|=0x0008000000000000;return xb(F64);}
  if(ay>0x7FF0000000000000){yb|=0x0008000000000000;return yb(F64);}
  if(!ay) {
    if(!(xb>>63))return y;
    result=sign|0x400921FB54442D18;return result(F64);
  }
  if(!ax || ay==0x7FF0000000000000 && ax!=0x7FF0000000000000) {
    result=sign|0x3FF921FB54442D18;return result(F64);
  }
  if(ax==0x7FF0000000000000) {
    if(ay==0x7FF0000000000000) {
      if(xb>>63)result=sign|0x4002D97C7F3321D2;
      else result=sign|0x3FE921FB54442D18;
    } else if(xb>>63)result=sign|0x400921FB54442D18;
    else result=sign;
    return result(F64);
  }
  k=(ay>>52);k-=ax>>52;
  if(k>60)z=0x3FF921FB54442D18(F64);
  else if(xb>>63 && k<-60)z=0;
  else z=I386PolarATan(ay(F64)/ax(F64));
  if(xb>>63) {
    if(yb>>63)return (z-pi_lo)-polar_pi;
    return polar_pi-(z-pi_lo);
  }
  result=z(U64)^sign;return result(F64);
}
