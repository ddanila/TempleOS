#ifndef I386_OPT_BRANCH_INCLUDED
#define I386_OPT_BRANCH_INCLUDED
#include "/Compiler/I386/Control.HH"
//Current owner's valid parser-produced graph. Null rejects an invalid entry.
//Allocation failure throws OutMem; unwind/discard the graph before retrying.
public extern CIntermediateCode *I386OptBranch(CI386Heap *heap,CCmpCtrl *cc,CIntermediateCode *node);
#endif
