Bool DLF(U8 *link,U8 *expected)
{
  I64 base=Fs->data_heap->used_u8s;
  U8 *actual=DocLinkFile(link);
  Bool ok;
  if(expected)ok=actual && !StrCmp(actual,expected);
  else ok=!actual;
  Free(actual);
  return ok && Fs->data_heap->used_u8s==base;
}
I64 JRContract(I64 drive)
{
  I64 mask=0;
  U8 *name=MStrPrint("%c:/NameAbs/Parent.HC",drive),*link;
  link=MStrPrint("FI:%s",name);if(DLF(link,name))mask|=1;Free(link);
  link=MStrPrint("FL:%s,17",name);if(DLF(link,name))mask|=2;Free(link);
  link=MStrPrint("PF:%s,Needle:4",name);if(DLF(link,name))mask|=4;Free(link);
  if(DLF("BF:Genesis,1:1",BIBLE_FILENAME))mask|=8;
  if(DLF("AI:123",NULL) && DLF("AL:123,17",NULL))mask|=16;
  if(DLF("DN:word",NULL) && DLF("HI:Index",NULL))mask|=32;
  if(DLF(NULL,NULL) && DLF("ZZ:any",NULL))mask|=64;
  if(DLF(name,name))mask|=128;
  Free(name);
  return mask;
}
