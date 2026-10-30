U8 *ExtChg(U8 *filename,U8 *extension)
{//Change filename extension.
  U8 *res=MAlloc(StrLen(filename)+1+StrLen(extension)+1);
  StrCpy(res,filename);
  if (FileExtDot(filename))
    FileExtRem(res);
  return CatPrint(res,".%s",extension);
}
