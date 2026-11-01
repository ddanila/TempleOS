Bool CopySingleZ(U8 *f1,U8 *f2) //Just one file
{
  U8 *file_buf=NULL;
  I64 size,attr=0,c;
  CDirEntry de;
  if (FileFind(f1,&de,FUF_JUST_FILES)) {
    Free(de.full_name);
    file_buf=FileRead(f1,&size,&attr);
    attr=FileAttr(f2,attr);
    if (file_buf) {
      "Copying %s to %s\n",f1,f2;
      c=FileWrite(f2,file_buf,size,de.datetime,attr);
      Free(file_buf);
      return ToBool(c);
    } else
      PrintErr("File not found: \"%s\".\n",f1);
  } else
    PrintErr("File not found: \"%s\".\n",f1);
  return FALSE;
}
