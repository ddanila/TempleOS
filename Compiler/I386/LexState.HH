#ifndef I386_LEX_STATE_INCLUDED
#define I386_LEX_STATE_INCLUDED
#include "/Compiler/LexState.HH"
#include "/Kernel/I386/Heap.HH"
//Private snapshot ownership, also checked before releasing an included file.
#define I386_LEX_SNAPSHOT_MAGIC 0x4C535031
class CI386LexSnapshot
{
  CLexFile file;
  CLexFile *active;
  CCmpCtrl *control;
  CI386Heap *heap;
  U32 signature;
};
public extern Bool I386LexPush(CI386Heap *heap,CCmpCtrl *cc);
public extern Bool I386LexPop(CI386Heap *heap,CCmpCtrl *cc,Bool restore=TRUE);
#endif
