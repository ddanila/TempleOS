#include "/Kernel/CompilerTypes.HH"
I64 EUInspectOpts(){CCmpCtrl *cc=Fs->last_cc;return cc->opts;}
I64 EUInspectAsm(){CCmpCtrl *cc=Fs->last_cc;return (cc->flags&CCF_ASM_EXPRESSIONS)!=0;}
I64 EUInspectMask(){CCmpCtrl *cc=Fs->last_cc;return cc->htc.hash_mask;}
I64 JRContract()
{
  I64 mask=0,old_opts,base;
  CCmpCtrl *boundary=Fs->last_cc;
  old_opts=boundary->opts;
  CLexHashTableContext context;
  MemCpy(&context,&boundary->htc,sizeof(CLexHashTableContext));
  context.old_flags|=CCF_ASM_EXPRESSIONS;
  context.hash_mask=HTG_TYPE_MASK;
  boundary->opts=0x12340000;
  if(ExePutS("EUInspectOpts();","Opts.HC")==0x12340000)mask|=1;
  if(ExePutS("EUInspectAsm();","Asm.HC",0,&context)==1)mask|=2;
  if(ExePutS("EUInspectMask();","Context.HC",0,&context)==HTG_TYPE_MASK)mask|=4;
  if(Fs->last_cc==boundary && boundary->opts==0x12340000)mask|=8;
  if(context.old_flags&CCF_ASM_EXPRESSIONS && context.hash_mask==HTG_TYPE_MASK)mask|=16;
  base=Fs->data_heap->used_u8s;
  ExePutS("EUInspectOpts();","Again.HC",0,&context);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  boundary->opts=old_opts;return mask;
}
