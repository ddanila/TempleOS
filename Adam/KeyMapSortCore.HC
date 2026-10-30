//Original key-map comparison over the first 32 bytes of each label.
U0 KMComparePrepare(U8 *buf,I64 *src)
{
  I64 i,*dst=buf;
  U8 *ptr;
  if (src) {
    *dst++=*src++;
    *dst++=*src++;
    *dst++=*src++;
    *dst++=*src++;
    *dst(U8 *)=0;
    if (ptr=StrMatch("SHIFT",buf)) {
      for (i=0;i<5;i++)
	ptr[i]=CH_SHIFT_SPACE;
      if (ptr=StrMatch("$$",buf))
	*ptr=255;
    }
  } else
    *buf=0;
}

I64 KMCompare(U8 *e1,U8 *e2)
{
  U8 buf1[STR_LEN],buf2[STR_LEN];
  KMComparePrepare(buf1,e1);
  KMComparePrepare(buf2,e2);
  return StrCmp(buf1,buf2);
}

