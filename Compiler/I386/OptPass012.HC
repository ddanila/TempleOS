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
CIntermediateCode *I386OptPass012(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,
  U0 (*diagnostic)(CCmpCtrl *cc,CIntermediateCode *node,I64 reason)=0)
{
  COptPass012Services services;
  CI386OptDiagnostic reporter;
  U32 irq;
  if(!I386CmpCodeOwner(heap,cc) || cc->pass<0 || cc->pass>2 || !types ||
      !types[RT_I64] || !types[RT_U64] || !types[RT_F64] ||
      types[RT_I64]->raw_type!=RT_I64 || types[RT_U64]->raw_type!=RT_U64 ||
      types[RT_F64]->raw_type!=RT_F64) return 0;
  irq=I386IrqSave;
  if(!cc->ps) cc->ps=I386HeapAlloc(heap,sizeof(CPrsStk),FALSE);
  I386IrqRestore(irq);
  if(!cc->ps) throw('OutMem',TRUE);
  if(I386HeapSize(heap,cc->ps)!=sizeof(CPrsStk)) return 0;
  cc->flags|=CCF_TARGET_I386;
  services.types=types; services.context=&reporter; services.report=&I386OptPass012Report;
  reporter.report=diagnostic;
  return OptPass012Core(cc,&services);
}
