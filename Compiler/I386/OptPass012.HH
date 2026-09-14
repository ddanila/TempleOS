#ifndef I386_OPT_PASS012_INCLUDED
#define I386_OPT_PASS012_INCLUDED
#include "/Compiler/I386/Control.HH"
#include "/Compiler/OptPass012.HH"
//Current owner's valid IR, pass 0..2 and borrowed internal types. Invalid setup returns null.
//Allocation failure throws OutMem; compiler diagnostics throw Compiler after reporting.
//The diagnostic callback borrows the graph and must return without mutating/reentering it.
public extern CIntermediateCode *I386OptPass012(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,
  U0 (*diagnostic)(CCmpCtrl *cc,CIntermediateCode *node,I64 reason)=0);
#endif
