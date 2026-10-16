public CDC *GRRead(U8 *filename,CTask *task=NULL)
{//TempleOS GR File.
  CDC	*dc=NULL;
  U8	*st=ExtDft(filename,"GR.Z"),
	*src=FileRead(st);
  if (src)
    dc=DCLoad(src,,task);
  Free(src);
  Free(st);
  return dc;
}
