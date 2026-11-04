I64 es_calls;
I64 ESValue(I64 x) {es_calls++;return x;}
I64 ESArgs(I8 a0,U8 a1,I16 a2,U16 a3,I32 a4,U32 a5,U8 *a6,
 I8 a7,U8 a8,I16 a9,U16 a10,I32 a11,U32 a12,U8 *a13,
 I8 a14,U8 a15,U32 a16)
{
 return a0==-1 && a1==255 && a2==-32768 && a3==65535 &&
  a4==-2147483648 && a5==0xFFFFFFFF && a6==NULL &&
  a7==-128 && a8==128 && a9==32767 && a10==32768 &&
  a11==2147483647 && a12==0x80000000 && a13==NULL &&
  a14==-2 && a15==254 && a16==0xDEADBEEF;
}
I64 ESZero() {return 42;}
I64 ESVariadic(U8 fixed,...)
{ return fixed==255 && argc==2 && argv[0]==0x123456789ABCDEF0 && argv[1]==-1; }
I64 ESContract()
{
 U8 canary[256];
 I64 i,mask=0;
 I64 (*fp)(I8 a0,U8 a1,I16 a2,U16 a3,I32 a4,U32 a5,U8 *a6,
  I8 a7,U8 a8,I16 a9,U16 a10,I32 a11,U32 a12,U8 *a13,
  I8 a14,U8 a15,U32 a16);
 I64 (*zero)();
 fp=&ESArgs;zero=&ESZero;
 for(i=0;i<256;i++)canary[i]=i^0xA5;
 if(ESArgs(0x1234FF,0x1234FF,0x12348000,0x1234FFFF,0x1234567880000000,
  0x12345678FFFFFFFF,NULL,0x123480,0x123480,0x12347FFF,0x12348000,
  0x123456787FFFFFFF,0x1234567880000000,NULL,0x1234FE,0x1234FE,0x12345678DEADBEEF))mask|=1;
 if((*fp)(0x1234FF,0x1234FF,0x12348000,0x1234FFFF,0x1234567880000000,
  0x12345678FFFFFFFF,NULL,0x123480,0x123480,0x12347FFF,0x12348000,
  0x123456787FFFFFFF,0x1234567880000000,NULL,0x1234FE,0x1234FE,0x12345678DEADBEEF))mask|=2;
 es_calls=0;
 if((*fp)(ESValue(-1),ESValue(255),ESValue(-32768),ESValue(65535),ESValue(-2147483648),
  ESValue(0xFFFFFFFF),ESValue(0),ESValue(-128),ESValue(128),ESValue(32767),ESValue(32768),
  ESValue(2147483647),ESValue(0x80000000),ESValue(0),ESValue(-2),ESValue(254),ESValue(0xDEADBEEF))
  && es_calls==17)mask|=4;
 if((*zero)()==42)mask|=8;
 if(ESVariadic(0x1234FF,0x123456789ABCDEF0,-1))mask|=16;
 for(i=0;i<256;i++)if(canary[i]!=(i^0xA5))return mask;
 return mask|32;
}

I64 ESFrameMutate(I64 *value) {*value=*value+1;return *value;}
I64 ESFrameContract()
{
 U8 large[1024];
 I64 a=40,b=2,*pointer=&a,**alias=&pointer,i,mask=0;
 F64 real=1.25,*real_pointer=&real;
 for(i=0;i<1024;i++)large[i]=i^0xA5;
 if(&a && *pointer==40 && **alias==40)mask|=1;
 es_calls=0;
 if((&a && ESValue(7)==7) && es_calls==1)mask|=2;
 if((FALSE && &a) || (&b && ESValue(9)==9))mask|=4;
 if(ESFrameMutate(*alias)==41 && a+b==43)mask|=8;
 if(&large[1023]-large==1023 && large[0]==0xA5 && large[1023]==0x5A)mask|=16;
 real+=2.5;
 if(Abs(*real_pointer-3.75)<0.000000000001 && real(U64)==0x400E000000000000)mask|=32;
 if(&pointer!=NULL && *alias==&a && &b!=&a)mask|=64;
 for(i=0;i<1024;i++)if(large[i]!=((i^0xA5)&255))return mask;
 return mask|128;
}
