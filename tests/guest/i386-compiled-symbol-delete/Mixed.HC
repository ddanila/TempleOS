I64 HDMixedGlobal=42;
class HDMixedClass { I64 value; };
I64 HDMixedFun(I64 value){return value+1;}
Bool HDRemove(U8 *name,I64 type)
{
  CHashSrcSym *entry=HashFind(name,Fs->hash_table,type);
  return entry && HashRemDel(entry,Fs->hash_table) &&
    !HashFind(name,Fs->hash_table,type);
}
I64 JRContract()
{
  I64 base,mask=0;
  CHashTable *table;
  CHashDefineStr *macro;
  if(HDRemove("HDMixedGlobal",HTT_GLBL_VAR))mask|=1;
  if(HDMixedFun(41)==42 && HDRemove("HDMixedFun",HTT_FUN))mask|=2;
  if(HDRemove("HDMixedClass",HTT_CLASS))mask|=4;
  base=Fs->data_heap->used_u8s;
  table=HashTableNew(32);macro=CAlloc(sizeof(CHashDefineStr));
  macro->str=StrNew("HD_PUBLIC_MACRO");macro->data=StrNew("42");
  macro->type=HTT_DEFINE_STR;HashAdd(macro,table);
  if(HashFind("HD_PUBLIC_MACRO",table,HTT_DEFINE_STR)==macro)mask|=8;
  if(HashRemDel(macro,table) && !HashFind("HD_PUBLIC_MACRO",table,HTT_DEFINE_STR))mask|=16;
  HashTableDel(table);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
