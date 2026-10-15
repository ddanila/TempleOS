//One cleanup stack for interleaved document and compositor resources.
class CNativeRenderScope {
  CNativeRenderScope *next;
  CI386Task *task;
  U0 (*previous_cleanup)(CI386Task *task);
  U0 (*release)(CNativeRenderScope *scope);
  CI386Task *resource_owner,*window_owner;
  U8 *resource;
  Bool retiring_resource,legacy_view;
};
CNativeRenderScope *native_render_scopes;
extern U0 NativeRenderCleanup(CI386Task *task);
U0 NativeRenderScopeOpen(CNativeRenderScope *scope,
  U0 (*release)(CNativeRenderScope *scope))
{
  U32 irq=I386IrqSave;
  scope->task=I386TaskSelf;scope->previous_cleanup=scope->task->cleanup;
  scope->resource_owner=scope->window_owner=NULL;
  scope->resource=NULL;scope->retiring_resource=scope->legacy_view=FALSE;
  scope->release=release;scope->next=native_render_scopes;
  native_render_scopes=scope;scope->task->cleanup=&NativeRenderCleanup;
  I386IrqRestore(irq);
}

Bool NativeRenderOwnerClosing(CI386Task *owner)
{
  return owner && (!TaskValidate(owner) ||
    owner->task_flags&(1<<TASKf_KILL_TASK));
}
Bool NativeRenderResourceRetiring(U8 *resource)
{
  CNativeRenderScope *scope=native_render_scopes;
  while(scope) {
    if(scope->resource==resource && scope->retiring_resource)return TRUE;
    scope=scope->next;
  }
  return FALSE;
}
U0 NativeRenderScopeBorrow(CNativeRenderScope *scope,CI386Task *owner,
  CI386Task *window_owner,U8 *resource)
{//Admission is cooperative/atomic: no yield before the association is published.
  if(NativeRenderOwnerClosing(owner) || NativeRenderOwnerClosing(window_owner) ||
      NativeRenderResourceRetiring(resource))throw('DocGone',TRUE);
  scope->resource_owner=owner;scope->window_owner=window_owner;
  scope->resource=resource;
}
U0 NativeRenderScopeRemove(CNativeRenderScope *scope)
{//Caller excludes IRQs; another task's live scope may precede this one.
  CNativeRenderScope *item=native_render_scopes,*previous=NULL;
  while(item && item!=scope) {previous=item;item=item->next;}
  if(!item)KernelStop;
  if(previous)previous->next=scope->next;
  else native_render_scopes=scope->next;
}
U0 NativeRenderScopeClose(CNativeRenderScope *scope)
{
  U32 irq=I386IrqSave;
  if(scope->task!=I386TaskSelf || scope->task->cleanup!=&NativeRenderCleanup)
    KernelStop;
  NativeRenderScopeRemove(scope);scope->task->cleanup=scope->previous_cleanup;
  I386IrqRestore(irq);
}
U0 NativeRenderCleanup(CI386Task *task)
{//Release in callback nesting order, including mixed document/frame scopes.
  CNativeRenderScope *scope;
  U0 (*previous)(CI386Task *task);
  U32 irq;
  while(TRUE) {
    irq=I386IrqSave;scope=native_render_scopes;
    while(scope && scope->task!=task)scope=scope->next;
    if(!scope)KernelStop;
    previous=scope->previous_cleanup;
    NativeRenderScopeRemove(scope);task->cleanup=previous;
    I386IrqRestore(irq);
    (*scope->release)(scope);
    if(previous!=&NativeRenderCleanup) {
      if(previous)(*previous)(task);
      return;
    }
  }
}
U0 NativeRenderDrainExiting(CI386Task *task)
{//Committed Exit abandons its own render frames before canceling other users.
  CNativeRenderScope *scope;
  U32 irq,finishing;
  while(task->cleanup==&NativeRenderCleanup) {
    irq=I386IrqSave;scope=native_render_scopes;
    while(scope && scope->task!=task)scope=scope->next;
    if(!scope)KernelStop;
    NativeRenderScopeRemove(scope);task->cleanup=scope->previous_cleanup;
    finishing=task->finishing;task->finishing=TRUE;
    I386IrqRestore(irq);
    //These native release functions do not yield. Suppress break delivery on
    //DocUnlock while Exit is committed, without invoking prior task cleanup.
    (*scope->release)(scope);
    irq=I386IrqSave;task->finishing=finishing;I386IrqRestore(irq);
  }
}
U0 NativeRenderRetire(CI386Task *owner,U8 *resource)
{
  CNativeRenderScope *scope;
  CI386Task *borrower;
  U32 irq;
  while(TRUE) {
    irq=I386IrqSave;scope=native_render_scopes;borrower=NULL;
    while(scope) {
      if(scope->task!=I386TaskSelf &&
          (resource && scope->resource==resource || !resource &&
           (scope->resource_owner==owner || scope->window_owner==owner))) {
        borrower=scope->task;break;
      }
      scope=scope->next;
    }
    I386IrqRestore(irq);
    if(!borrower)return;
    //The immortal root cannot be killed. Its explicit renderer must return;
    //scheduled refresh uses cancellable managed tasks instead.
    if(borrower==I386TaskSelf->owner->root)Yield;
    else if(borrower==sys_winmgr_task) {
      //Public Kill protects WinMgr. Owner retirement requests internal unwind.
      irq=I386IrqSave;borrower->task_flags|=1<<TASKf_KILL_TASK;I386IrqRestore(irq);
      do Yield;
      while(TaskValidate(borrower) && borrower->task_flags&(1<<TASKf_KILL_TASK));
    } else {
      if(!(*native_user_providers.kill)(borrower,TRUE,FALSE))Yield;
    }
    //Never retain a stack scope across yielding; callbacks can recover a kill.
  }
}
U0 NativeRenderOwnerRetire(CI386Task *task)
{
  NativeRenderDrainExiting(task);
  NativeRenderRetire(task,NULL);
}

Bool NativeLegacyViewActive(CTask *task)
{
  CNativeRenderScope *scope=native_render_scopes;
  while(scope) {
    if(scope->task==task && scope->legacy_view)return TRUE;
    scope=scope->next;
  }
  return FALSE;
}
class CNativeLegacyViewScope:CNativeRenderScope {
  CDoc *old_put,*old_display;
  Bool restore_docs;
};
U0 NativeLegacyViewRelease(CNativeRenderScope *base)
{
  CNativeLegacyViewScope *scope=base;
  if(scope->restore_docs) {
    scope->task->put_doc=scope->old_put;scope->task->display_doc=scope->old_display;
  }
  Free(scope);
}
CNativeLegacyViewScope *NativeLegacyViewOpen(Bool restore_docs=FALSE)
{
  CNativeLegacyViewScope *scope=CAlloc(sizeof(CNativeLegacyViewScope));
  scope->old_put=Fs->put_doc;scope->old_display=Fs->display_doc;
  scope->restore_docs=restore_docs;
  NativeRenderScopeOpen(scope,&NativeLegacyViewRelease);scope->legacy_view=TRUE;
  return scope;
}
U0 NativeLegacyViewClose(CNativeLegacyViewScope *scope)
{
  if(!scope)return;
  NativeRenderScopeClose(scope);NativeLegacyViewRelease(scope);
}
