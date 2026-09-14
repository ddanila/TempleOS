#ifndef I386_LEX_STATE_INCLUDED
#define I386_LEX_STATE_INCLUDED
#include "/Compiler/LexState.HH"
#include "/Kernel/I386/Heap.HH"
public extern Bool I386LexPush(CI386Heap *heap,CCmpCtrl *cc);
public extern Bool I386LexPop(CI386Heap *heap,CCmpCtrl *cc,Bool restore=TRUE);
#endif
