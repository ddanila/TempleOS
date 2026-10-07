I64 fa_drive;
U8 *FAName(U8 *name){U8 *result=StrNew(name);result[0]=fa_drive;return result;}
Bool FADir(U8 *name){U8 *p=FAName(name);Bool ok=DirMk(p);Free(p);return ok;}
I64 FAWrite(U8 *name){U8 *p=FAName(name);I64 size=FileWrite(p,"DATA",4);Free(p);return size;}
Bool FAC(U8 *name,I64 flags,U8 *expected)
{
  I64 base=Fs->data_heap->used_u8s;
  U8 *input=FAName(name),*want=FAName(expected),*result=FileNameAbs(input,flags);
  Bool ok=result && !StrCmp(result,want);
  Free(result);Free(input);Free(want);
  return ok && Fs->data_heap->used_u8s==base;
}
I64 JRContract(I64 drive,Bool setup=TRUE)
{
  I64 mask=0;fa_drive=drive;
  if(!setup || FADir("C:/NameAbs") && FADir("C:/NameAbs/A") && FADir("C:/NameAbs/A/B") &&
      FAWrite("C:/NameAbs/Parent.HC")>0 && FAWrite("C:/NameAbs/Only.HC")>0)mask|=1;
  if(FAC("C:/NameAbs/A/B/../../Parent.HC",0,"C:/NameAbs/Parent.HC"))mask|=2;
  if(FAC("C:/NameAbs/A/B/Parent.HC",FUF_SCAN_PARENTS,"C:/NameAbs/Parent.HC"))mask|=4;
  if(FAC("C:/NameAbs/Only.HC.Z",FUF_Z_OR_NOT_Z,"C:/NameAbs/Only.HC"))mask|=8;
  if(FAC("C:/NameAbs/A/B/Only.HC.Z",FUF_Z_OR_NOT_Z|FUF_SCAN_PARENTS,"C:/NameAbs/Only.HC"))mask|=16;
  if(FAC("C:/NameAbs/Missing.HC",FUF_Z_OR_NOT_Z,"C:/NameAbs/Missing.HC"))mask|=32;
  return mask;
}
