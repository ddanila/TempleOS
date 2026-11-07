U0 CXLog(U8 *s){while(*s)OutU8(0xE9,*s++);}

U64 CXLoad1(U8 *src,U64 n,I64 seed,U64 *v)
{SetRFlags(0x202|seed);*v=src[n];v[1]=src[n];return Carry;}
U64 CXStore1(U8 *src,U64 n,U64 value,I64 seed,U64 *v)
{SetRFlags(0x202|seed);src[n]=value;*v=src[n];v[1]=src[n];return Carry;}
U64 CXLoad2(U16 *src,U64 n,I64 seed,U64 *v)
{SetRFlags(0x202|seed);*v=src[n];v[1]=src[n];return Carry;}
U64 CXStore2(U16 *src,U64 n,U64 value,I64 seed,U64 *v)
{SetRFlags(0x202|seed);src[n]=value;*v=src[n];v[1]=src[n];return Carry;}
U64 CXLoad4(U32 *src,U64 n,I64 seed,U64 *v)
{SetRFlags(0x202|seed);*v=src[n];v[1]=src[n];return Carry;}
U64 CXStore4(U32 *src,U64 n,U64 value,I64 seed,U64 *v)
{SetRFlags(0x202|seed);src[n]=value;*v=src[n];v[1]=src[n];return Carry;}
U64 CXLoad8(U64 *src,U64 n,I64 seed,U64 *v)
{SetRFlags(0x202|seed);*v=src[n];v[1]=src[n];return Carry;}
U64 CXStore8(U64 *src,U64 n,U64 value,I64 seed,U64 *v)
{SetRFlags(0x202|seed);src[n]=value;*v=src[n];v[1]=src[n];return Carry;}
U0 CXCheck()
{
 U8 *src=MAlloc(128),*s;U64 *data=CAlloc(3072),*p=data,cf,value;
 I64 kind,n,seed,i;
 for(kind=0;kind<8;kind++)for(n=0;n<8;n++)for(seed=0;seed<2;seed++) {
  for(i=0;i<128;i++)src[i]=i+1;value=0x8877665544332211+n;
  switch(kind) {
   case 0:cf=CXLoad1(src,n,seed,p);break;
   case 1:cf=CXLoad2(src,n,seed,p);break;
   case 2:cf=CXLoad4(src,n,seed,p);break;
   case 3:cf=CXLoad8(src,n,seed,p);break;
   case 4:cf=CXStore1(src,n,value,seed,p);break;
   case 5:cf=CXStore2(src,n,value,seed,p);break;
   case 6:cf=CXStore4(src,n,value,seed,p);break;
   case 7:cf=CXStore8(src,n,value,seed,p);break;
  }
  p[2]=cf;p+=3;
 }
 Free(src);s=MStrPrint("EXPORT carry-addresses.bin %X %X\n",data,(p-data)*8);CXLog(s);Free(s);
 CXLog("CARRY ADDRESSES DONE\n");Sleep(1000);
}
CXCheck;
