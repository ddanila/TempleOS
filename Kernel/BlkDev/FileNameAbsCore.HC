U8 *FileNameAbsCore(U8 *_filename,I64 fuf_flags,U8 *(*construct)(U8 *filename))
{
  CDirEntry de;
  U8 *res;
  if(!_filename) _filename="";
  res=(*construct)(_filename);
  if (fuf_flags && FileFind(res,&de,fuf_flags|FUF_JUST_FILES)) {
    Free(res);
    res=de.full_name;
  }
  return res;
}
