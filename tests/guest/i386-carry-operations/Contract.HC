U0 COLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U64 COLeft(U64 a,I64 n,I64 seed,U64 *v)
{SetRFlags(0x202|seed);a<<=n;*v=a;return Carry;}
U64 CORight(U64 a,I64 n,I64 seed,U64 *v)
{SetRFlags(0x202|seed);a>>=n;*v=a;return Carry;}
U64 COSigned(I64 a,I64 n,I64 seed,U64 *v)
{SetRFlags(0x202|seed);a>>=n;*v=a;return Carry;}
U64 COValue;
U64 COAdd(U64 a,U64 b,U64 *v){a+=b;COValue=a;*v=COValue;return Carry;}
U64 COSub(U64 a,U64 b,U64 *v){a-=b;COValue=a;*v=COValue;return Carry;}
U0 COCheck()
{
  U64 patterns[8],*data=CAlloc(9728),*p=data,cf;
  I64 counts[10],i,j,seed,kind;U8 *s;
  patterns[0]=0;patterns[1]=1;patterns[2]=0x80000000;patterns[3]=0x100000000;
  patterns[4]=0x8000000000000000;patterns[5]=0xFFFFFFFFFFFFFFFF;
  patterns[6]=0x89ABCDEF01234567;patterns[7]=0x0123456789ABCDEF;
  counts[0]=0;counts[1]=1;counts[2]=31;counts[3]=32;counts[4]=33;
  counts[5]=63;counts[6]=64;counts[7]=65;counts[8]=95;counts[9]=127;
  for(kind=0;kind<3;kind++)for(i=0;i<8;i++)for(j=0;j<10;j++)for(seed=0;seed<2;seed++) {
    if(!kind)cf=COLeft(patterns[i],counts[j],seed,p);
    else if(kind==1)cf=CORight(patterns[i],counts[j],seed,p);
    else cf=COSigned(patterns[i],counts[j],seed,p);
    p[1]=cf;p+=2;
  }
  for(kind=0;kind<2;kind++)for(i=0;i<8;i++)for(j=0;j<8;j++) {
    if(!kind)cf=COAdd(patterns[i],patterns[j],p);
    else cf=COSub(patterns[i],patterns[j],p);
    p[1]=cf;p+=2;
  }
  s=MStrPrint("EXPORT carry-operations.bin %X %X\n",data,(p-data)*8);COLog(s);Free(s);
  COLog("CARRY OPERATIONS DONE\n");Sleep(1000);
}
COCheck;
