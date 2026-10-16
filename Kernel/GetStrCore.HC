//Original prompted string input and default handling.
U8 *GetStr(U8 *msg=NULL,U8 *dft=NULL,I64 flags=0)
{//Returns a $LK,"MAlloc",A="MN:MAlloc"$()ed prompted string.  See $LK,"Flags",A="MN:GSF_SHIFT_ESC_EXIT"$.
  U8 *st;
  if (msg)
    "" msg,dft;
  st=(*fp_getstr2)(flags);
  if (!*st) {
    Free(st);
    if (dft)
      return StrNew(dft);
    else
      return StrNew("");
  }
  return st;
}

