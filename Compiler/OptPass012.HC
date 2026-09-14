#include "/Compiler/OptPass012Core.HC"
U0 OptPass012Report(U8 *context,CCmpCtrl *cc,CIntermediateCode *node,I64 reason)
{
  switch(reason) {
    case OPT012_WARN_DEREF: LexWarn(cc,"Dereference U0 "); break;
    case OPT012_WARN_ASSIGN: LexWarn(cc,"Assign U0 "); break;
    case OPT012_ERROR_OPCODE:
      "Pass:%d Missing IC hndlr\n",cc->pass;
      ICPut(cc,node);
      LexExcept(cc,"Compiler Optimization Error at ");
      break;
    case OPT012_ERROR_STACK:
      "Pass:%d Stk:%08X\n",cc->pass,cc->ps->ptr;
      LexExcept(cc,"Compiler Optimization Error at ");
  }
}
CIntermediateCode *OptPass012(CCmpCtrl *cc)
{
  COptPass012Services services;
  if(!cc->ps) cc->ps=MAlloc(sizeof(CPrsStk));
  services.types=cmp.internal_types; services.context=0; services.report=&OptPass012Report;
  return OptPass012Core(cc,&services);
}
