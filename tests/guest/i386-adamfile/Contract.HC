I64 AdamFileContract()
{
  I64 mask=0;
  U8 *old=StrNew(Fs->cur_dir);
  if(Adam("%d+%d;",19,23)==42)mask|=1;
  if(Adam("Adam(\"%%d+%%d;\",19,23);")==42)mask|=2;
  if(AdamFile("::/Probe/AFCase",FALSE)==42)mask|=4;
  if(AdamFile("::/Probe/AFCase.HC",FALSE)==42)mask|=8;
  if(!StrCmp(old,Fs->cur_dir))mask|=16;
  Free(old);
  return mask;
}
