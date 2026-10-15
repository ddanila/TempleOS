//Protect selection and all document/border callbacks in one task update.
class CNativeTaskUpdateScope:CNativeRenderScope {
  CTask *target;
  CD3I64 *saved_scroll;
  Bool scroll_saved;
};
U0 NativeTaskUpdateRelease(CNativeRenderScope *base)
{
  CNativeTaskUpdateScope *scope=base;
  if(scope->scroll_saved) {
    scope->scroll_saved=FALSE;
    WinScrollRestore(scope->target,scope->saved_scroll);
  }
}
U0 NativeTaskUpdateOpen(CNativeTaskUpdateScope *scope,CTask *task,CD3I64 *scroll)
{
  scope->target=task;scope->saved_scroll=scroll;scope->scroll_saved=FALSE;
  NativeRenderScopeOpen(scope,&NativeTaskUpdateRelease);
  if(!task)throw('DocGone',TRUE);
  NativeRenderScopeBorrow(scope,task,task,NULL);
}
#define DOC_UPDATE_TASK_SCOPE_LOCAL CNativeTaskUpdateScope native_update_scope
#define DOC_UPDATE_TASK_SCOPE_OPEN NativeTaskUpdateOpen(&native_update_scope,task,&saved_scroll)
#define DOC_UPDATE_TASK_SCOPE_RELEASE NativeTaskUpdateRelease(&native_update_scope)
#define DOC_UPDATE_TASK_SCOPE_CLOSE NativeRenderScopeClose(&native_update_scope)
#define DOC_UPDATE_TASK_SCROLL_SAVE WinScrollNull(task,&saved_scroll);native_update_scope.scroll_saved=TRUE
#define DOC_UPDATE_TASK_SCROLL_RESTORE NativeTaskUpdateRelease(&native_update_scope)
