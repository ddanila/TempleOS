#include "/Adam/DolDoc/DocEdStateCore.HC"
class CNativeDocEdScope:CNativeRenderScope {
  CDocEdState *state;
  CNativeRenderScope borrows[5];
  I64 count;
  Bool opened;
};
U0 NativeDocEdBorrowRelease(CNativeRenderScope *base) {}
Bool NativeDocEdBreakUnlock(CTask *task)
{ return I386TaskBreakUnlock(task); }
U0 NativeDocEdAbandon(CNativeRenderScope *base)
{//Committed teardown must neither yield nor invoke user/window callbacks.
  CNativeDocEdScope *scope=base;
  CDocEdState *state=scope->state;
  U8 *title;
  CTask *previous;
  CDoc *parent;
  scope->opened=FALSE;scope->count=0;
  state->released=TRUE;
  //Release only this task's actual ownership, including an incoming lock.
  DocUnlockCore(state->doc,state->task,&NativeDocEdBreakUnlock);
  previous=state->old_doc_win_task;
  if(!TaskValidate(previous) || previous->task_num!=state->old_doc_win_num)
    previous=state->doc->mem_task;
  if(previous && NativeRenderOwnerClosing(previous))previous=NULL;
  if(state->doc->win_task==state->task)state->doc->win_task=previous;
  parent=state->doc->parent_doc;
  if(state->doc!=state->old_display_doc && parent==state->old_display_doc)
    parent=state->old_doc_parent;
  if(parent && parent==state->old_doc_parent &&
      (NativeRenderOwnerClosing(parent->mem_task) || NativeRenderResourceRetiring(parent)))
    parent=NULL;
  state->doc->parent_doc=parent;
  state->task->put_doc=state->old_put_doc;
  state->task->display_doc=state->old_display_doc;
  state->task->border_doc=state->old_border_doc;
  state->task->text_attr=state->old_attr;
  title=state->old_task_title;state->old_task_title=NULL;
  if(title && state->task->title_src!=TTS_LOCKED_CONST) {
    state->task->title_src=state->old_title_src;
    StrCpy(state->task->task_title,title);
  }
  Free(title);
  //DocNew owns this temporary border in the exiting task's heap. Detach it;
  //owner retirement drains render borrowers before that heap is reclaimed.
  //DocDel here could yield waiting for a manager borrower during stack drain.
  if(state->bdoc && state->bdoc->mem_task!=state->task)KernelStop;
  state->bdoc=NULL;
}
U0 NativeDocEdBorrow(CNativeDocEdScope *scope,CDoc *doc)
{
  CNativeRenderScope *borrow;
  if(!doc)return;
  if(doc->doc_signature!=DOC_SIGNATURE_VAL)throw('DocGone',TRUE);
  borrow=&scope->borrows[scope->count++];
  NativeRenderScopeOpen(borrow,&NativeDocEdBorrowRelease);
  NativeRenderScopeBorrow(borrow,doc->mem_task,scope->state->task,doc);
}
U0 NativeDocEdOpen(CNativeDocEdScope *scope,CDocEdState *state)
{
  scope->state=state;scope->count=0;scope->opened=FALSE;
  NativeRenderScopeOpen(scope,&NativeDocEdAbandon);scope->opened=TRUE;
  state->old_doc_parent=state->doc->parent_doc;
  state->old_doc_win_task=state->doc->win_task;state->old_doc_win_num=0;
  if(TaskValidate(state->old_doc_win_task))
    state->old_doc_win_num=state->old_doc_win_task->task_num;
  NativeDocEdBorrow(scope,state->doc);
  NativeDocEdBorrow(scope,state->old_put_doc);
  NativeDocEdBorrow(scope,state->old_display_doc);
  NativeDocEdBorrow(scope,state->old_border_doc);
  NativeDocEdBorrow(scope,state->old_doc_parent);
}
U0 NativeDocEdClose(CNativeDocEdScope *scope)
{
  if(!scope->opened)return;
  while(scope->count)NativeRenderScopeClose(&scope->borrows[--scope->count]);
  NativeRenderScopeClose(scope);scope->opened=FALSE;
}
U0 NativeDocEdRestore(CNativeDocEdScope *scope,CDocEdState *state)
{
  try {DocEdStateRestore(state);}
  catch {NativeDocEdClose(scope);}
  NativeDocEdClose(scope);
}
#define DOC_ED_SCOPE_LOCAL CNativeDocEdScope native_doc_ed_scope
#define DOC_ED_SCOPE_OPEN NativeDocEdOpen(&native_doc_ed_scope,&state)
#define DOC_ED_RESTORE NativeDocEdRestore(&native_doc_ed_scope,&state)
#include "/Adam/DolDoc/DocEdCore.HC"
