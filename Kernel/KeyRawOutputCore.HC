Bool KDRawPutKey(I64 ch,I64)
{
  if (IsRaw) {
    RawPutChar(ch);
    return TRUE;
  } else
    return FALSE;
}

Bool KDRawPutS(U8 *st)
{
  I64 ch;
  if (IsRaw) {
    while (ch=*st++)
      RawPutChar(ch);
    return TRUE;
  } else
    return FALSE;
}

