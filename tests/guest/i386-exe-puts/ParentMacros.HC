#include "/Kernel/CompilerTypes.HH"
I64 JRContract()
{
  I64 mask=0,base;
  CCmpCtrl *boundary=Fs->last_cc;
  CLexHashTableContext context;
  MemCpy(&context,&boundary->htc,sizeof(CLexHashTableContext));
  context.define_hash_table=context.glbl_hash_table;
  if(ExePutS("#define EU_PARENT_MACRO 42\n","Define.HC",CCF_JUST_LOAD,&context))mask|=1;
  if(ExePutS("EU_PARENT_MACRO;","Read.HC",0,&context)==42)mask|=2;
  if(HashFind("EU_PARENT_MACRO",context.define_hash_table,HTT_DEFINE_STR))mask|=4;
  if(ExePutS("I64 EUPublishedFunction(){return EU_PARENT_MACRO+1;}","MacroFunction.HC",CCF_JUST_LOAD,&context))mask|=8;
  if(ExePutS("EUPublishedFunction();","Call.HC",0,&context)==43)mask|=16;
  if(Fs->last_cc==boundary && context.define_hash_table==boundary->htc.glbl_hash_table)mask|=32;
  base=Fs->data_heap->used_u8s;
  if(ExePutS("EU_PARENT_MACRO;","Again.HC",0,&context)==42 && Fs->data_heap->used_u8s==base)mask|=64;
  return mask;
}
