#include "/Kernel/CompilerTypes.HH"
I64 JRContract()
{
  I64 mask=0;
  CCmpCtrl *boundary=Fs->last_cc;
  CLexHashTableContext context;
  MemCpy(&context,&boundary->htc,sizeof(CLexHashTableContext));
  if(ExePutS("I64 EUPublishedValue=40;","ParentGlobal.HC",CCF_JUST_LOAD,&context))mask|=1;
  if(HashFind("EUPublishedValue",context.glbl_hash_table,HTT_GLBL_VAR))mask|=2;
  if(ExePutS("EUPublishedValue=40;EUPublishedValue+2;","ParentRead.HC",0,&context)==42)mask|=4;
  if(ExePutS("I64 EUPublishedFunction(){return EUPublishedValue+2;}","ParentFunction.HC",CCF_JUST_LOAD,&context))mask|=8;
  if(ExePutS("EUPublishedFunction();","ParentCall.HC",0,&context)==42)mask|=16;
  if(Fs->last_cc==boundary && context.glbl_hash_table==boundary->htc.glbl_hash_table)mask|=32;
  if(ExePutS("EUPublishedValue=41;EUPublishedFunction();","ParentAgain.HC",0,&context)==43)mask|=64;
  return mask;
}
