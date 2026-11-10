//Focused ownership dispatch: real shared core, instrumented branch policies.
#define OptPass012CorePolicy PolicyProbeCore
#define OptPass012Core PolicyProbeDefault
#include "/Compiler/CompilerA.HH"
#include "/Compiler/ICInfo.HC"
#include "/Compiler/PrsStack.HC"
#include "/Compiler/TargetSize.HC"
#include "/Compiler/OptCode.HC"
#include "/Compiler/OptTypes.HC"
#include "/Compiler/OptSize.HC"
I64 policy_default_calls[2];
CIntermediateCode *PolicyDefaultZero(CCmpCtrl *cc,CIntermediateCode *node)
{policy_default_calls[0]++;return node;}
CIntermediateCode *PolicyDefaultNonzero(CCmpCtrl *cc,CIntermediateCode *node)
{policy_default_calls[1]++;return node;}
#define OptBrZero PolicyDefaultZero
#define OptBrNotZero PolicyDefaultNonzero
#include "/Compiler/OptPass012Core.HC"
ICInfoInit;
I64 policy_calls[2],policy_bad,policy_trace[17];
U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
CIntermediateCode *PolicyZero(CCmpCtrl *cc,CIntermediateCode *node)
{policy_calls[0]++;return node;}
CIntermediateCode *PolicyNonzero(CCmpCtrl *cc,CIntermediateCode *node)
{policy_calls[1]++;return node;}
U0 PolicyReport(U8 *context,CCmpCtrl *cc,CIntermediateCode *node,I64 reason)
{policy_bad++;throw('Policy');}
U0 ProbePolicy()
{
 U8 *line;I64 index,native,which,pass,expected,before=Fs->data_heap->used_u8s;
 CCmpCtrl control,*cc=&control;CPrsStk stack;
 CIntermediateCode immediate,branch,*head=&control.coc.coc_head;COptPass012Services services;
 policy_bad=0;
 services.types=cmp.internal_types;services.context=NULL;services.report=&PolicyReport;
 for(native=0;native<2;native++)for(which=0;which<2;which++){
  MemSet(&control,0,sizeof(control));MemSet(&stack,0,sizeof(stack));
  MemSet(&immediate,0,sizeof(immediate));MemSet(&branch,0,sizeof(branch));
  cc->ps=&stack;head->next=&immediate;head->last=&branch;
  immediate.last=head;immediate.next=&branch;branch.last=&immediate;branch.next=head;
  immediate.ic_code=IC_IMM_I64;immediate.ic_data=7;immediate.ic_class=cmp.internal_types[RT_I64];
  branch.ic_code=IC_BR_ZERO;if(which)branch.ic_code=IC_BR_NOT_ZERO;
  expected=3;if(native)expected=0;
  cc->flags&=~CCF_TARGET_I386;if(native)cc->flags|=CCF_TARGET_I386;
  policy_calls[0]=policy_calls[1]=0;policy_default_calls[0]=policy_default_calls[1]=0;
  for(pass=0;pass<3;pass++){cc->pass=pass;PolicyProbeCore(cc,&services,&PolicyZero,&PolicyNonzero);}
  if(policy_calls[which]!=expected || policy_calls[!which] || policy_default_calls[0] || policy_default_calls[1] || cc->error_cnt || cc->warning_cnt)policy_bad++;
  for(pass=0;pass<3;pass++){cc->pass=pass;PolicyProbeDefault(cc,&services);}
  if(policy_default_calls[which]!=expected || policy_default_calls[!which] || policy_calls[which]!=expected)policy_bad++;
  index=(native*2+which)*4;
  policy_trace[index]=policy_calls[0];policy_trace[index+1]=policy_calls[1];
  policy_trace[index+2]=policy_default_calls[0];policy_trace[index+3]=policy_default_calls[1];

 }
 policy_trace[16]=Fs->data_heap->used_u8s-before;
 line=MStrPrint("EXPORT optimizer-policy.bin %X %X\n",policy_trace,sizeof(policy_trace));Report(line);Free(line);
 if(policy_bad || policy_trace[16])Report("FAIL optimizer policy dispatch\n");
 else Report("DONE optimizer policy dispatch\n");
}
ProbePolicy;
