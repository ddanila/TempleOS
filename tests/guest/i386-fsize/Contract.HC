I64 FSContract()
{
  CFile f;I64 mask=0;
  MemSet(&f,0,sizeof(CFile));
  if(FSize(NULL)==0)mask|=1;
  if(FSize(&f)==0)mask|=2;
  f.de.size=0x1234567887654321;f.flags=FF_WRITE;f.fblk_num=42;
  if(FSize(&f)==0x1234567887654321 && f.flags==FF_WRITE && f.fblk_num==42)mask|=4;
  f.de.size=-17;if(FSize(&f)==-17)mask|=8;
  return mask;
}
