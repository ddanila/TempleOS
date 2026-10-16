U8 *ExtDft(U8 *filename,U8 *extension)
{//Give extension if has none.
  U8 *res=MAlloc(StrLen(filename)+1+StrLen(extension)+1);
  return FileNameWriteDefault(res,filename,extension);
}
