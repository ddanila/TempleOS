/*
 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
 * Developed at SunSoft, a Sun Microsystems, Inc. business.
 * Permission to use, copy, modify, and distribute this software is freely
 * granted, provided that this notice is preserved.
 */
//HolyC adaptation of netlib.org/fdlibm/k_sin.c and k_cos.c.
//The full-range integer reducer is our separately tested implementation.
#include "/Kernel/I386/FloatTrigReduction.HC"
F64 I386TrigKernelSin(F64 x,F64 y)
{
  F64 z,v,r,s1=0xBFC5555555555549(F64),s2=0x3F8111111110F8A6(F64),
    s3=0xBF2A01A019C161D5(F64),s4=0x3EC71DE357B1FE7D(F64),
    s5=0xBE5AE5E68A2B9CEB(F64),s6=0x3DE5D93A5ACFD57C(F64);
  if((x(U64)&0x7FFFFFFFFFFFFFFF)<0x3E40000000000000)return x;
  z=x*x;v=z*x;r=s2+z*(s3+z*(s4+z*(s5+z*s6)));
  if(!y)return x+v*(s1+z*r);
  return x-((z*(0.5*y-v*r)-y)-v*s1);
}
F64 I386TrigKernelCos(F64 x,F64 y)
{
  U64 ix=(x(U64)>>32)&0x7FFFFFFF,bits;
  F64 z,r,qx,hz,a,c1=0x3FA555555555554C(F64),c2=0xBF56C16C16C15177(F64),
    c3=0x3EFA01A019CB1590(F64),c4=0xBE927E4F809C52AD(F64),
    c5=0x3E21EE9EBDB4B1C4(F64),c6=0xBDA8FAE9BE8838D4(F64);
  if(ix<0x3E400000)return 1.0;
  z=x*x;r=z*(c1+z*(c2+z*(c3+z*(c4+z*(c5+z*c6)))));
  if(ix<0x3FD33333)return 1.0-(0.5*z-(z*r-x*y));
  if(ix>0x3FE90000)qx=0.28125;
  else {bits=(ix-0x00200000)<<32;qx=bits(F64);}
  hz=0.5*z-qx;a=1.0-qx;
  return a-(hz-(z*r-x*y));
}
F64 I386TrigSin(F64 x)
{
  U64 bits=x(U64),magnitude=bits&0x7FFFFFFFFFFFFFFF;
  F64 head,tail;
  I64 quadrant;
  if(magnitude>0x7FF0000000000000){bits|=0x8000000000000;return bits(F64);}
  if(magnitude==0x7FF0000000000000)return 0xFFF8000000000000(F64);
  quadrant=I386TrigReduce(x,&head,&tail);
  switch(quadrant) {
    case 0:return I386TrigKernelSin(head,tail);
    case 1:return I386TrigKernelCos(head,tail);
    case 2:return -I386TrigKernelSin(head,tail);
    case 3:return -I386TrigKernelCos(head,tail);
  }
  return 0xFFF8000000000000(F64);
}
F64 I386TrigCos(F64 x)
{
  U64 bits=x(U64),magnitude=bits&0x7FFFFFFFFFFFFFFF;
  F64 head,tail;
  I64 quadrant;
  if(magnitude>0x7FF0000000000000){bits|=0x8000000000000;return bits(F64);}
  if(magnitude==0x7FF0000000000000)return 0xFFF8000000000000(F64);
  quadrant=I386TrigReduce(x,&head,&tail);
  switch(quadrant) {
    case 0:return I386TrigKernelCos(head,tail);
    case 1:return -I386TrigKernelSin(head,tail);
    case 2:return -I386TrigKernelCos(head,tail);
    case 3:return I386TrigKernelSin(head,tail);
  }
  return 0xFFF8000000000000(F64);
}
