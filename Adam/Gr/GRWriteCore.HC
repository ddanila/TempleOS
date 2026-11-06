public I64 GRWrite(U8 *filename,CDC *dc,I64 dcsf_flags=DCSF_COMPRESSED)
{//TempleOS GR File.
  I64	size;
  U8	*st=ExtDft(filename,"GR.Z"),
	*src=DCSave(dc,&size,dcsf_flags);
  FileWrite(st,src,size);
  Free(st);
  Free(src);
  return size;
}

