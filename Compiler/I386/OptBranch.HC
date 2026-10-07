//Include after Control.HC: allocation policy uses its private ownership record.
#include "/Compiler/I386/OptBranch.HH"
#include "/Compiler/CompilerA.HH"
//The containing module supplies the native throw import or implementation.
#include "/Compiler/OptCode.HC"
CIntermediateCode *OptFree(CCmpCtrl *cc,CIntermediateCode *node)
{
  CI386CmpCtrl *owned=cc;
  if(!I386ICRetire(owned->heap,cc,node)) throw('Compiler',TRUE);
  return 0;
}
CCodeMisc *COCMiscNew(CCmpCtrl *cc,I64 type)
{
  CI386CmpCtrl *owned=cc;
  CCodeMisc *node=I386COCMiscNew(owned->heap,cc,type);
  if(!node) throw('OutMem',TRUE);
  return node;
}
#include "/Compiler/OptBranch.HC"
CIntermediateCode *I386OptBranch(CI386Heap *heap,CCmpCtrl *cc,CIntermediateCode *node)
{
  CI386CodeAllocation *record;
  if(!I386CmpCodeOwner(heap,cc) || !(record=I386ICLifetime(heap,node)) ||
      record->control!=cc || record->kind!=1 || record->allocation!=node ||
      (node->ic_code!=IC_BR_ZERO && node->ic_code!=IC_BR_NOT_ZERO)) return 0;
  if(node->ic_code==IC_BR_ZERO) return OptBrZero(cc,node);
  return OptBrNotZero(cc,node);
}
