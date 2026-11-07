U0 CALog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U64 CAUnsigned(U64 a,U64 b,U64 *v){a*=b;*v=a;v[1]=a;return Carry;}
U64 CASigned(I64 a,I64 b,U64 *v){a*=b;*v=a;v[1]=a;return Carry;}
U64 CASquare(U64 a,U64 *v){a=SqrU64(a);*v=a;v[1]=a;return Carry;}
U64 CASquareSigned(I64 a,U64 *v){a=SqrI64(a);*v=a;v[1]=a;return Carry;}
U64 CANegate(U64 a,U64 *v){*v=-a;v[1]=*v;return Carry;}
U64 CAInc(U64 a,I64 seed,U64 *v){SetRFlags(0x202|seed);*v=++a;v[1]=a;return Carry;}
U64 CADec(U64 a,I64 seed,U64 *v){SetRFlags(0x202|seed);*v=--a;v[1]=a;return Carry;}
U64 CAPostInc(U64 a,I64 seed,U64 *v){SetRFlags(0x202|seed);*v=a++;v[1]=a;return Carry;}
U64 CAPostDec(U64 a,I64 seed,U64 *v){SetRFlags(0x202|seed);*v=a--;v[1]=a;return Carry;}
U0 CACheck()
{
 U64 a[8],*data=CAlloc(5184),*p=data,cf;I64 i,j,k,seed;U8 *s;
 a[0]=0;a[1]=1;a[2]=0x80000000;a[3]=0x100000000;a[4]=0x8000000000000000;
 a[5]=0xFFFFFFFFFFFFFFFF;a[6]=0x89ABCDEF01234567;a[7]=0x0123456789ABCDEF;
 for(k=0;k<2;k++)for(i=0;i<8;i++)for(j=0;j<8;j++) {
  if(k)cf=CASigned(a[i],a[j],p);else cf=CAUnsigned(a[i],a[j],p);
  p[2]=cf;p+=3;
 }
 for(k=0;k<2;k++)for(i=0;i<8;i++){if(k)cf=CASquareSigned(a[i],p);else cf=CASquare(a[i],p);p[2]=cf;p+=3;}
 for(i=0;i<8;i++){p[2]=CANegate(a[i],p);p+=3;}
 for(k=0;k<4;k++)for(i=0;i<8;i++)for(seed=0;seed<2;seed++) {
  if(!k)cf=CAInc(a[i],seed,p);else if(k==1)cf=CADec(a[i],seed,p);
  else if(k==2)cf=CAPostInc(a[i],seed,p);else cf=CAPostDec(a[i],seed,p);
  p[2]=cf;p+=3;
 }
 s=MStrPrint("EXPORT carry-arithmetic.bin %X %X\n",data,(p-data)*8);CALog(s);Free(s);
 CALog("CARRY ARITHMETIC DONE\n");Sleep(1000);
}
CACheck;
