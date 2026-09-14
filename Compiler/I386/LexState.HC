#include "/Compiler/I386/LexState.HH"
#include "/Compiler/LexState.HC"
#include "/Kernel/I386/Cpu.HH"
#define I386_LEX_SNAPSHOT_MAGIC 0x4C535031
class CI386LexSnapshot
{
  CLexFile file;
  CLexFile *active;
  CCmpCtrl *control;
  CI386Heap *heap;
  U32 signature;
};
Bool I386LexPush(CI386Heap *heap,CCmpCtrl *cc)
{
  CI386LexSnapshot *snapshot;
  U32 flags;
  if(!cc || !cc->lex_include_stk) return FALSE;
  flags=I386IrqSave;
  snapshot=I386HeapAlloc(heap,sizeof(CI386LexSnapshot),TRUE);
  I386IrqRestore(flags);
  if(!snapshot) return FALSE;
  snapshot->active=cc->lex_include_stk; snapshot->control=cc;
  snapshot->heap=heap; snapshot->signature=I386_LEX_SNAPSHOT_MAGIC;
  LexPrepareSnapshot(cc); LexSnapshotCopy(cc,&snapshot->file);
  LexSnapshotAttach(cc,&snapshot->file);
  return TRUE;
}
Bool I386LexPop(CI386Heap *heap,CCmpCtrl *cc,Bool restore=TRUE)
{
  CI386LexSnapshot *snapshot;
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(!cc || !(snapshot=cc->lex_prs_stk) ||
      I386HeapSize(heap,snapshot)!=sizeof(CI386LexSnapshot)) goto done;
  if(snapshot->signature!=I386_LEX_SNAPSHOT_MAGIC || snapshot->heap!=heap ||
      snapshot->control!=cc || restore && snapshot->active!=cc->lex_include_stk) goto done;
  if(restore) LexSnapshotRestore(cc);
  else LexSnapshotDetach(cc);
  snapshot->signature=0;
  result=I386HeapFree(heap,snapshot);
done:
  I386IrqRestore(flags);
  return result;
}
