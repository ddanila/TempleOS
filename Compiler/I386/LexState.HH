#ifndef I386_LEX_STATE_INCLUDED
#define I386_LEX_STATE_INCLUDED
#include "/Compiler/LexState.HH"
#include "/Kernel/I386/Heap.HH"
//Private snapshot ownership, also checked before releasing an included file.
#define I386_LEX_SNAPSHOT_MAGIC 0x4C535031
class CI386LexSavedFile
{
  CLexFile file;
  CLexFile *active;
  CI386LexSavedFile *next;
};
class CI386LexSnapshot
{
  CLexFile file;
  CLexFile *active;
  CCmpCtrl *control;
  CI386Heap *heap;
  U32 signature;
  CI386LexSavedFile *parents;
};
public extern Bool I386LexSnapshotValid(CI386Heap *heap,CCmpCtrl *cc,CI386LexSnapshot *snapshot);
public extern Bool I386LexSnapshotsPin(CI386Heap *heap,CCmpCtrl *cc,CLexFile *file,Bool *pinned);
public extern Bool I386LexSnapshotsSourceFree(CI386Heap *heap,CCmpCtrl *cc,U8 *source);
public extern Bool I386LexPush(CI386Heap *heap,CCmpCtrl *cc);
public extern Bool I386LexPop(CI386Heap *heap,CCmpCtrl *cc,Bool restore=TRUE);
#endif
