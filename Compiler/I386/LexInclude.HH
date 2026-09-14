#ifndef I386_LEX_INCLUDE_INCLUDED
#define I386_LEX_INCLUDE_INCLUDED
#include "/Compiler/I386/LexFiles.HH"
//Borrowed synchronous service. Success publishes an owned input child on cc.
//Failure preserves input state at callback entry and retains no temporary allocations.
//Name is borrowed from the current token; copy it before retaining or changing token state.
class CI386LexIncludeService {
  U8 *context;
  Bool (*push)(U8 *context,CI386Heap *heap,CCmpCtrl *cc,U8 *name);
};
#endif
