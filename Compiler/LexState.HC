#include "/Compiler/LexState.HH"
//Live, exclusively owned control/file/snapshot records. Snapshots borrow their payloads.
U0 LexBackupLastChar(CCmpCtrl *cc)
{
  CLexFile *tmpf=cc->lex_include_stk;
  tmpf->buf_ptr=cc->cur_buf_ptr;
  if (cc->flags & CCF_USE_LAST_U16) {
    tmpf->last_U16=cc->last_U16;
    cc->flags&=~CCF_USE_LAST_U16;
  } else
    tmpf->last_U16=0;
}

U0 LexPrepareSnapshot(CCmpCtrl *cc)
{
  LexBackupLastChar(cc);
  if(cc->lex_include_stk->last_U16) cc->flags|=CCF_USE_LAST_U16;
}
U0 LexSnapshotCopy(CCmpCtrl *cc,CLexFile *snapshot)
{
  U8 *source=cc->lex_include_stk,*dest=snapshot;
  I64 i;
  for(i=0;i<sizeof(CLexFile);i++) dest[i]=source[i];
}
U0 LexSnapshotAttach(CCmpCtrl *cc,CLexFile *snapshot)
{
  snapshot->next=cc->lex_prs_stk;
  cc->lex_prs_stk=snapshot;
}
CLexFile *LexSnapshotDetach(CCmpCtrl *cc)
{
  CLexFile *snapshot=cc->lex_prs_stk;
  cc->lex_prs_stk=snapshot->next;
  return snapshot;
}
CLexFile *LexSnapshotRestore(CCmpCtrl *cc)
{
  CLexFile *snapshot=cc->lex_prs_stk;
  U8 *source=snapshot,*dest=cc->lex_include_stk;
  I64 i;
  cc->cur_buf_ptr=snapshot->buf_ptr;
  if(cc->last_U16=snapshot->last_U16) cc->flags|=CCF_USE_LAST_U16;
  else cc->flags&=~CCF_USE_LAST_U16;
  //Preserve the active file's include link; snapshot.next is a different stack.
  for(i=sizeof(U8 *);i<sizeof(CLexFile);i++) dest[i]=source[i];
  return LexSnapshotDetach(cc);
}
