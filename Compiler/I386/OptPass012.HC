//Included after Control.HC, OptBranch.HC and the software numerical runtime.
#include "/Compiler/I386/OptPass012.HH"
#include "/Kernel/I386/Float.HH"
#include "/Kernel/I386/Bool.HH"
#include "/Compiler/ICInfo.HC"
#include "/Compiler/PrsStack.HC"
#include "/Compiler/TargetSize.HC"
#include "/Compiler/OptTypes.HC"
#include "/Compiler/OptSize.HC"
#include "/Compiler/OptPass012Core.HC"
class CI386OptDiagnostic { U0 (*report)(CCmpCtrl *cc,CIntermediateCode *node,I64 reason); };
U0 I386OptPass012Report(U8 *context,CCmpCtrl *cc,CIntermediateCode *node,I64 reason)
{
  CI386OptDiagnostic *diagnostic=context;
  if(reason<OPT012_ERROR_OPCODE) cc->warning_cnt++;
  else cc->error_cnt++;
  if(diagnostic->report) (*diagnostic->report)(cc,node,reason);
  if(reason>=OPT012_ERROR_OPCODE) throw('Compiler',TRUE);
}
CIntermediateCode *I386OptPass012Sized(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,
  I64 stack_bytes,U0 (*diagnostic)(CCmpCtrl *cc,CIntermediateCode *node,I64 reason))
{
  COptPass012Services services;
  CI386OptDiagnostic reporter;
  U32 irq;
  if(!I386CmpCodeOwner(heap,cc) || cc->pass<0 || cc->pass>2 || !types ||
      !types[RT_I64] || !types[RT_U64] || !types[RT_F64] ||
      types[RT_I64]->raw_type!=RT_I64 || types[RT_U64]->raw_type!=RT_U64 ||
      types[RT_F64]->raw_type!=RT_F64) return 0;
  irq=I386IrqSave;
  if(!cc->ps) cc->ps=I386HeapAlloc(heap,stack_bytes,FALSE);
  I386IrqRestore(irq);
  if(!cc->ps) throw('OutMem',TRUE);
  if(I386HeapSize(heap,cc->ps)!=stack_bytes) return 0;
  cc->flags|=CCF_TARGET_I386;
  services.types=types; services.context=&reporter; services.report=&I386OptPass012Report;
  reporter.report=diagnostic;
  return OptPass012Core(cc,&services);
}
CIntermediateCode *I386OptPass012(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,
  U0 (*diagnostic)(CCmpCtrl *cc,CIntermediateCode *node,I64 reason)=0)
{//Public callers retain the complete parser stack for inspection and reuse.
  return I386OptPass012Sized(heap,cc,types,sizeof(CPrsStk),diagnostic);
}
CIntermediateCode *I386FrontendOptPass012(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types)
{//Frontend-only scratch lifetime; the public optimizer keeps its stack view.
  CPrsStk *borrowed=cc->ps;
  I64 stack_bytes=sizeof(CPrsStk);
  //OptPass012Core uses stk[0..254] and resets ptr2, but never uses stk2.
  //Keep the original layout, widths and stack limit; omit only unused storage.
  //Exceptions leave this allocation control-owned for the normal unwind.
  if(!borrowed) stack_bytes=offset(CPrsStk.stk2);
  CIntermediateCode *result=I386OptPass012Sized(heap,cc,types,stack_bytes,0);
  U32 irq;
  if(!borrowed && cc->ps) {
    irq=I386IrqSave;
    if(!I386HeapFree(heap,cc->ps)) { I386IrqRestore(irq); throw('Compiler',TRUE); }
    cc->ps=0;
    I386IrqRestore(irq);
  }
  return result;
}
