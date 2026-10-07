#include "/Kernel/CompilerTypes.HH"
U0 EUStage()
{
  CCmpCtrl *parent=Fs->last_cc;
  CLexHashTableContext context;
  MemCpy(&context,&parent->htc,sizeof(CLexHashTableContext));
  ExePutS("I64 EUUnwindValue=42;I64 EUUnwindFunction(){return EUUnwindValue;}","BeforeThrow.HC",0,&context);
  throw('EUOuter',TRUE);
}
I64 JRContract()
{
  I64 mask=0;
  CCmpCtrl *boundary=Fs->last_cc;
  try {ExePutS("EUStage();","ThrowParent.HC");}
  catch {if(Fs->except_ch=='EUOuter')mask|=1;Fs->catch_except=TRUE;}
  if(Fs->last_cc==boundary)mask|=2;
  if(HashFind("EUUnwindValue",Fs->hash_table,HTT_GLBL_VAR))mask|=4;
  if(HashFind("EUUnwindFunction",Fs->hash_table,HTT_FUN))mask|=8;
  if(mask&4 && ExePutS("EUUnwindValue;","AfterThrow.HC")==42)mask|=16;
  if(mask&8 && ExePutS("EUUnwindFunction();","AfterThrowCall.HC")==42)mask|=32;
  return mask;
}
