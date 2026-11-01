Bool CFileNameTo(U8 *dst,U8 *src)
{
  MemSet(dst,0,CDIR_FILENAME_LEN);
  if (!FileNameChk(src))
    return FALSE;
  StrCpy(dst,src);
  return TRUE;
}

