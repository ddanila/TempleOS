/*
 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
 *
 * Developed at SunSoft, a Sun Microsystems, Inc. business.
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice
 * is preserved.
 */
//HolyC adaptation of https://www.netlib.org/fdlibm/e_log.c and e_log10.c.
//Integer bit access and explicit exceptional results replace C word aliases
//and FPU exception generation. Arithmetic uses the i386 software F64 backend.
#include "/Kernel/I386/Float.HH"
#include "/Kernel/I386/FloatMath.HH"
F64 Ln(F64 x)
{
  U64 bits=x(U64),magnitude=bits&0x7FFFFFFFFFFFFFFF;
  I64 k=0,hx,i,j;
  F64 hfsq,f,s,z,r,w,t1,t2,dk,
    ln2_hi=0x3FE62E42FEE00000(F64),ln2_lo=0x3DEA39EF35793C76(F64),
    lg1=0x3FE5555555555593(F64),lg2=0x3FD999999997FA04(F64),
    lg3=0x3FD2492494229359(F64),lg4=0x3FCC71C51D8E78AF(F64),
    lg5=0x3FC7466496CB03DE(F64),lg6=0x3FC39A09D078C69F(F64),
    lg7=0x3FC2F112DF3E5244(F64);
  if(magnitude>0x7FF0000000000000) {
    bits|=0x0008000000000000; return bits(F64);
  }
  if(!magnitude) { bits=0xFFF0000000000000; return bits(F64); }
  if(bits>>63) { bits=0xFFF8000000000000; return bits(F64); }
  if(magnitude==0x7FF0000000000000) return x;
  if(magnitude<0x0010000000000000) { k=-54; x*=0x4350000000000000(F64); }
  hx=x(U64)>>32;
  k+=(hx>>20)-1023;
  hx&=0x000FFFFF;
  i=(hx+0x95F64)&0x100000;
  x(U64)=(x(U64)&0xFFFFFFFF)|((hx|(i^0x3FF00000))<<32);
  k+=i>>20;
  f=x-1.0;
  if((0x000FFFFF&(2+hx))<3) {
    if(f==0.0) {
      if(k==0) return 0.0;
      dk=ToF64(k); return dk*ln2_hi+dk*ln2_lo;
    }
    r=f*f*(0.5-0x3FD5555555555555(F64)*f);
    if(k==0) return f-r;
    dk=ToF64(k); return dk*ln2_hi-((r-dk*ln2_lo)-f);
  }
  s=f/(2.0+f); dk=ToF64(k); z=s*s; i=hx-0x6147A;
  w=z*z; j=0x6B851-hx;
  t1=w*(lg2+w*(lg4+w*lg6));
  t2=z*(lg1+w*(lg3+w*(lg5+w*lg7)));
  i|=j; r=t2+t1;
  if(i>0) {
    hfsq=0.5*f*f;
    if(k==0) return f-(hfsq-s*(hfsq+r));
    return dk*ln2_hi-((hfsq-(s*(hfsq+r)+dk*ln2_lo))-f);
  }
  if(k==0) return f-s*(f-r);
  return dk*ln2_hi-((s*(f-r)-dk*ln2_lo)-f);
}
F64 Log10(F64 x)
{
  U64 bits=x(U64),magnitude=bits&0x7FFFFFFFFFFFFFFF;
  I64 k=0,hx,i;
  F64 y,z;
  if(magnitude>0x7FF0000000000000) {
    bits|=0x0008000000000000; return bits(F64);
  }
  if(!magnitude) { bits=0xFFF0000000000000; return bits(F64); }
  if(bits>>63) { bits=0xFFF8000000000000; return bits(F64); }
  if(magnitude==0x7FF0000000000000) return x;
  if(magnitude<0x0010000000000000) { k=-54; x*=0x4350000000000000(F64); }
  hx=x(U64)>>32; k+=(hx>>20)-1023;
  i=(k<0); hx=(hx&0x000FFFFF)|((0x3FF-i)<<20);
  y=ToF64(k+i);
  x(U64)=(x(U64)&0xFFFFFFFF)|(hx<<32);
  z=y*0x3D59FEF311F12B36(F64)+0x3FDBCB7B1526E50E(F64)*Ln(x);
  return z+y*0x3FD34413509F6000(F64);
}
