#include "/Kernel/CompilerTypes.HH"
U0 EURepeatStage()
{
  CCmpCtrl *parent=Fs->last_cc;
  CLexHashTableContext context;
  MemCpy(&context,&parent->htc,sizeof(CLexHashTableContext));
  ExePutS("42;","EmptyChild.HC",0,&context);
  throw('EURepeat',TRUE);
}
I64 JRContract()
{
  I64 mask=0,i,caught=0,data=Fs->data_heap->used_u8s,code=Fs->code_heap->used_u8s;
  Bool controls=TRUE,data_ok=TRUE,code_ok=TRUE;
  CCmpCtrl *boundary=Fs->last_cc;
  for(i=0;i<10;i++) {
    try {ExePutS("EURepeatStage();","RepeatParent.HC");}
    catch {if(Fs->except_ch=='EURepeat')caught++;Fs->catch_except=TRUE;}
    if(Fs->last_cc!=boundary)controls=FALSE;
    if(Fs->data_heap->used_u8s!=data)data_ok=FALSE;
    if(Fs->code_heap->used_u8s!=code)code_ok=FALSE;
  }
  if(caught==10)mask|=1;
  if(controls)mask|=2;
  if(data_ok)mask|=4;
  if(code_ok)mask|=8;
  return mask;
}
