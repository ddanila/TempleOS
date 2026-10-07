#include "/Kernel/CompilerTypes.HH"
I64 JRContract()
{
  I64 base=Fs->data_heap->used_u8s,mask=0;
  CCmpCtrl *boundary=Fs->last_cc;
  CLexHashTableContext context;
  CHashTable *table=HashTableNew(32);
  CHashDefineStr *macro=CAlloc(sizeof(CHashDefineStr));
  table->next=Fs->hash_table;
  macro->str=StrNew("EU_PRIVATE_NUMBER");macro->type=HTT_DEFINE_STR;
  macro->data=StrNew("42");HashAdd(macro,table);
  MemCpy(&context,&boundary->htc,sizeof(CLexHashTableContext));
  context.glbl_hash_table=context.local_hash_table=context.hash_table_lst=table;
  context.define_hash_table=table;
  if(ExePutS("EU_PRIVATE_NUMBER;","Private.HC",0,&context)==42)mask|=1;
  if(!HashFind("EU_PRIVATE_NUMBER",Fs->hash_table,HTT_DEFINE_STR))mask|=2;
  ExePutS("I64 EUContextValue=42;","PrivateDecl.HC",0,&context);
  if(HashFind("EUContextValue",table,HTT_GLBL_VAR) &&
      !HashFind("EUContextValue",Fs->hash_table,HTT_GLBL_VAR))mask|=4;
  if(ExePutS("EUContextValue;","PrivateRead.HC",0,&context)==42)mask|=8;
  if(Fs->last_cc==boundary && context.glbl_hash_table==table)mask|=16;
  table->next=NULL;HashTableDel(table);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
