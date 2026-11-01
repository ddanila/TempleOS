Bool FATNameTo(U8 *dst,U8 *src)
{
  I64 i;
  MemSet(dst,CH_SPACE,11);
  if (!FileNameChk(src))
    return FALSE;
  if (!StrCmp(src,"..")) {
    *dst='.';
    dst[1]='.';
    return TRUE;
  } else if (!StrCmp(src,".")) {
    *dst='.';
    return TRUE;
  }
  i=0;
  while (i<8 && *src && *src!='.')
    dst[i++]=ToUpper(*src++);
  i=8;
  if (*src=='.') src++;
  while (*src) {
    if (*src!='.' && i<11)
      dst[i++]=ToUpper(*src);
    src++;
  }
  return TRUE;
}

I64 FATNameXSum(U8 *src)
{
  I64 i,res=0;
  for (i=0;i<11;i++)
    if (res&1)
      res.u8[0]=0x80+res>>1+*src++;
    else
      res.u8[0]=res>>1+*src++;
  return res;
}

Bool FATFromName(U8 *dst,U8 *src)
{
  I64 i,j,k=0;
  for (j=7;j>=0 && src[j]==CH_SPACE;j--);
  for(i=0;i<=j;i++)
    dst[k++]=src[i];
  for (j=10;j>=8 && src[j]==CH_SPACE;j--);
  if (*src!='.' && j!=7)
    dst[k++]='.';
  for(i=8;i<=j;i++)
    dst[k++]=src[i];
  dst[k++]=0;
  return FileNameChk(dst);
}

