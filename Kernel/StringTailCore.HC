U8 *StrLastOcc(U8 *src,U8 *marker)
{//Point to last occurrence of market set in str.
  I64 ch;
  U8 *res=NULL;
  while (ch=*src++)
    if (StrOcc(marker,ch))
      res=src-1;
  return res;
}

U8 *StrLastRem(U8 *src,U8 *marker,U8 *dst=NULL)
{//Remove last str segment and place in dst buf or NULL.
  U8 *ptr;
  if (ptr=StrLastOcc(src,marker)) {
    if (dst)
      StrCpy(dst,ptr+1);
    *ptr=0;
  } else {
    if (dst)
      StrCpy(dst,src);
    *src=0;
  }
  return dst;
}

