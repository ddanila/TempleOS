#include "/Compiler/I386/LexState.HH"
#include "/Compiler/I386/LexFiles.HH"
#include "/Compiler/LexState.HC"
#include "/Kernel/I386/Cpu.HH"
U0 I386LexSavedCopy(CLexFile *source,CLexFile *dest)
{
  I64 i;
  U8 *s=source,*d=dest;
  for(i=0;i<sizeof(CLexFile);i++) d[i]=s[i];
}
Bool I386LexPush(CI386Heap *heap,CCmpCtrl *cc)
{
  CI386LexSnapshot *snapshot;
  CI386LexSavedFile *saved,**tail,*next;
  CLexFile *parent;
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(!cc || !cc->lex_include_stk) goto done;
  snapshot=I386HeapAlloc(heap,sizeof(CI386LexSnapshot),TRUE);
  if(!snapshot) goto done;
  snapshot->active=cc->lex_include_stk; snapshot->control=cc;
  snapshot->heap=heap; snapshot->signature=I386_LEX_SNAPSHOT_MAGIC;
  //Allocate all parent positions before changing the caller's input state.
  tail=&snapshot->parents;
  if(I386LexFileOwned(heap,cc,snapshot->active)) {
    for(parent=snapshot->active->next;parent;parent=parent->next) {
      if(!I386LexFileOwned(heap,cc,parent)) goto failed;
      saved=I386HeapAlloc(heap,sizeof(CI386LexSavedFile),TRUE);
      if(!saved) goto failed;
      saved->active=parent; I386LexSavedCopy(parent,&saved->file);
      *tail=saved; tail=&saved->next;
    }
  }
  LexPrepareSnapshot(cc); LexSnapshotCopy(cc,&snapshot->file);
  LexSnapshotAttach(cc,&snapshot->file); result=TRUE;
  goto done;
failed:
  for(saved=snapshot->parents;saved;saved=next) {
    next=saved->next; I386HeapFree(heap,saved);
  }
  I386HeapFree(heap,snapshot);
done:
  I386IrqRestore(flags); return result;
}
Bool I386LexFileIsActive(CCmpCtrl *cc,CLexFile *file)
{
  CLexFile *active;
  for(active=cc->lex_include_stk;active;active=active->next)
    if(active==file) return TRUE;
  return FALSE;
}
Bool I386LexPop(CI386Heap *heap,CCmpCtrl *cc,Bool restore=TRUE)
{
  CI386LexSnapshot *snapshot;
  CI386LexSavedFile *saved,*next;
  CLexFile *file;
  U32 flags=I386IrqSave;
  Bool result=FALSE,found,pinned;
  if(!cc || !(snapshot=cc->lex_prs_stk) ||
      !I386LexSnapshotValid(heap,cc,snapshot)) goto done;
  if(!I386LexSnapshotsPin(heap,cc,snapshot->active,&pinned)) goto done;
  if(restore) {
    found=snapshot->active==cc->lex_include_stk;
    for(saved=snapshot->parents;saved;saved=saved->next)
      if(saved->active==cc->lex_include_stk) found=TRUE;
    if(!found) goto done;
    cc->lex_include_stk=snapshot->active;
    for(saved=snapshot->parents;saved;saved=saved->next)
      I386LexSavedCopy(&saved->file,saved->active);
    LexSnapshotRestore(cc);
  } else LexSnapshotDetach(cc);
  //Detached raw sources survive until the last snapshot releases its reference.
  file=snapshot->active;
  if(I386LexFileOwned(heap,cc,file) && !I386LexFileIsActive(cc,file)) {
    if(!I386LexSnapshotsPin(heap,cc,file,&pinned)) goto done;
    if(!pinned && !I386LexFileReleaseDetached(heap,cc,file)) goto done;
  }
  for(saved=snapshot->parents;saved;saved=next) {
    next=saved->next; file=saved->active;
    if(!I386LexFileIsActive(cc,file)) {
      if(!I386LexSnapshotsPin(heap,cc,file,&pinned)) goto done;
      if(!pinned && !I386LexFileReleaseDetached(heap,cc,file)) goto done;
    }
    I386HeapFree(heap,saved);
  }
  snapshot->signature=0; result=I386HeapFree(heap,snapshot);
done:
  I386IrqRestore(flags); return result;
}
