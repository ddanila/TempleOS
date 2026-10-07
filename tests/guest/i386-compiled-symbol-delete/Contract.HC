I64 HDCompiled=42;
I64 JRContract()
{
  I64 mask=0;
  CHashSrcSym *entry=HashFind("HDCompiled",Fs->hash_table,HTT_GLBL_VAR);
  if(entry)mask|=1;
  if(entry && HashRemDel(entry,Fs->hash_table))mask|=2;
  if(!HashFind("HDCompiled",Fs->hash_table,HTT_GLBL_VAR))mask|=4;
  return mask;
}
