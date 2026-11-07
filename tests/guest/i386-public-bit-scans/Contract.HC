U0 BSLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 BSRecord(I64 *out,U64 value)
{
  out[0]=value;out[1]=Bsf(value);out[2]=Bsr(value);
}
U0 BSCheck()
{
  I64 *r=MAlloc(577*3*8),i;U64 value=0x123456789ABCDEF0;U8 *s;
  BSRecord(r,0);
  for(i=0;i<64;i++)BSRecord(r+3*(i+1),1(U64)<<i);
  for(i=0;i<512;i++) {
    value^=value<<13;value^=value>>7;value^=value<<17;
    BSRecord(r+3*(65+i),value);
  }
  s=MStrPrint("EXPORT public-bit-scans.bin %X %X\n",r,577*3*8);BSLog(s);Free(s);
  BSLog("PUBLIC BIT SCANS DONE\n");Sleep(1000);
}
BSCheck;
