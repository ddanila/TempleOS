I64 EFCount;
I64 ExeFileContract()
{
  I64 mask=0;
  U8 *before=StrNew(Fs->cur_dir);
  EFCount=0;
  ExeFile("::/Probe/EFCase");
  if(EFCount==3)mask|=1;
  ExeFile("::/Probe/EFCase.HC",CCF_CMD_LINE);
  if(EFCount==6)mask|=2;
  if(!StrCmp(before,Fs->cur_dir))mask|=4;
  Free(before);
  return mask;
}
