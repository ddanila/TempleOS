#include "/Kernel/CompilerTypes.HH"
I64 JRContract()
{
  I64 mask=0;
  CCmpCtrl *boundary=Fs->last_cc;
  CLexHashTableContext context;
  MemCpy(&context,&boundary->htc,sizeof(CLexHashTableContext));
  if(ExePutS("extern class EUPBase;","Forward.HC",CCF_JUST_LOAD,&context))mask|=1;
  if(ExePutS("class EUPBase {I64 value;};","Complete.HC",CCF_JUST_LOAD,&context))mask|=2;
  if(ExePutS("class EUPChild:EUPBase {I64 extra;};","Derived.HC",CCF_JUST_LOAD,&context))mask|=4;
  if(ExePutS("sizeof(EUPChild);","Layout.HC",0,&context)==16)mask|=8;
  if(ExePutS("EUPChild EUPObject;EUPObject.value=40;EUPObject.extra=2;EUPObject.value+EUPObject.extra;","Object.HC",0,&context)==42)mask|=16;
  ExePutS("I64 EUPublishedFunction(){return EUPObject.value+EUPObject.extra;}","Function.HC",CCF_JUST_LOAD,&context);
  if(ExePutS("EUPublishedFunction();","Call.HC",0,&context)==42)mask|=32;
  if(Fs->last_cc==boundary && ExePutS("EUPObject.extra=3;EUPublishedFunction();","Again.HC",0,&context)==43)mask|=64;
  return mask;
}
