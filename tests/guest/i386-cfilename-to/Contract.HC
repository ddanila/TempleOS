Bool CNZero(U8 *p,I64 start,I64 end)
{I64 i;for(i=start;i<end;i++)if(p[i])return FALSE;return TRUE;}
I64 CNContract()
{
 U8 out[40],long_name[39];I64 i,mask=0;
 MemSet(out,0xA5,40);if(CFileNameTo(out+1,"HELLO.HC") && !StrCmp(out+1,"HELLO.HC") && CNZero(out+1,9,38) && out[0]==0xA5 && out[39]==0xA5)mask|=1;
 MemSet(out,0xA5,40);if(!CFileNameTo(out+1,"bad/name") && CNZero(out+1,0,38) && out[0]==0xA5 && out[39]==0xA5)mask|=2;
 if(CFileNameTo(out+1,".") && !StrCmp(out+1,".") && CFileNameTo(out+1,"..") && !StrCmp(out+1,".."))mask|=4;
 MemSet(out,0xA5,40);if(!CFileNameTo(out+1,"") && CNZero(out+1,0,38))mask|=8;
 for(i=0;i<37;i++)long_name[i]='A';long_name[37]=0;
 if(CFileNameTo(out+1,long_name) && !StrCmp(out+1,long_name))mask|=16;
 long_name[37]='A';long_name[38]=0;
 MemSet(out,0xA5,40);if(!CFileNameTo(out+1,long_name) && CNZero(out+1,0,38))mask|=32;
 MemSet(out,0xA5,40);if(!CFileNameTo(out+1,NULL) && CNZero(out+1,0,38) && out[0]==0xA5 && out[39]==0xA5)mask|=64;
 return mask;
}
