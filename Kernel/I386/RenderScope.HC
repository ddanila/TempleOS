//One cleanup stack for interleaved document and compositor resources.
class CNativeRenderScope {
  CNativeRenderScope *next;
  CI386Task *task;
  U0 (*previous_cleanup)(CI386Task *task);
  U0 (*release)(CNativeRenderScope *scope);
};
CNativeRenderScope *native_render_scopes;
extern U0 NativeRenderCleanup(CI386Task *task);
U0 NativeRenderScopeOpen(CNativeRenderScope *scope,
  U0 (*release)(CNativeRenderScope *scope))
{
  U32 irq=I386IrqSave;
  scope->task=I386TaskSelf;scope->previous_cleanup=scope->task->cleanup;
  scope->release=release;scope->next=native_render_scopes;
  native_render_scopes=scope;scope->task->cleanup=&NativeRenderCleanup;
  I386IrqRestore(irq);
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
