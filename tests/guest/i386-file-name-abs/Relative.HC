Bool FAR(U8 *name,U8 *expected)
{
  I64 base=Fs->data_heap->used_u8s;
  U8 *result=FileNameAbs(name);
  Bool ok=result && !StrCmp(result,expected);
  Free(result);return ok && Fs->data_heap->used_u8s==base;
}
I64 JRContract(I64 drive,U8 *home_dir)
{
  I64 mask=0;
  U8 *old=FileNameAbs(""),*directory=MStrPrint("%c:/NameAbs/A/B",drive);
  U8 *sibling=MStrPrint("%c:/NameAbs/A/Sibling.HC",drive);
  U8 *parent=MStrPrint("%c:/NameAbs/Parent.HC",drive);
  U8 *home=MStrPrint("%sProbe.HC",home_dir);
  if(Cd(directory))mask|=1;
  if(FAR("../Sibling.HC",sibling))mask|=2;
  if(FAR("/NameAbs/Parent.HC",parent))mask|=4;
  if(FAR("~/Probe.HC",home))mask|=8;
  if(FAR("::/NameAbs/Parent.HC",parent))mask|=16;
  if(Cd(old))mask|=32;
  Free(home);Free(parent);Free(sibling);Free(directory);Free(old);
  return mask;
}
