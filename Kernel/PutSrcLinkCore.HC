Bool PutSrcLink(U8 *addr,I64 cnt=1,U8 *buf=NULL)
{//Put to StdOut a $LK,"DolDoc",A="FI:::/Doc/DolDocOverview.DD"$ file,line link to src of addr.
  U8 *src;
  if (src=SrcEdLink(addr,cnt)) {
    if (buf)
      StrPrint(buf,"$$LK,\"%p\",A=\"%s\"$$",addr,src);
    else
      "$$LK,\"%p\",A=\"%s\"$$",addr,src;
    Free(src);
    return TRUE;
  } else if (buf)
    *buf=0;
  return FALSE;
}

