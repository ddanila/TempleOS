//Stack-resident render scopes remain live until scheduler task cleanup runs.
class CNativeDocRecalcScope {
  CNativeDocRecalcScope *next;
  CI386Task *task;
  U0 (*previous_cleanup)(CI386Task *task);
  CDoc *doc;
  Bool *unlock;
  CDC **dc;
  I32 **depth;
  U8 **tag;
};
CNativeDocRecalcScope *native_doc_recalc_scopes;
extern U0 NativeDocRecalcCleanup(CI386Task *task);
U0 NativeDocRecalcScopeOpen(CNativeDocRecalcScope *scope,CDoc *doc,
  Bool *unlock,CDC **dc,I32 **depth,U8 **tag)
{
  U32 irq=I386IrqSave;
  scope->task=I386TaskSelf;scope->previous_cleanup=scope->task->cleanup;
  scope->doc=doc;scope->unlock=unlock;scope->dc=dc;scope->depth=depth;scope->tag=tag;
  scope->next=native_doc_recalc_scopes;native_doc_recalc_scopes=scope;
  scope->task->cleanup=&NativeDocRecalcCleanup;
  I386IrqRestore(irq);
}
U0 NativeDocRecalcScopeRemove(CNativeDocRecalcScope *scope)
{//Caller holds IRQ exclusion. Other tasks can have interleaved live scopes.
  CNativeDocRecalcScope *item=native_doc_recalc_scopes,*previous=NULL;
  while(item && item!=scope) {previous=item;item=item->next;}
  if(!item)KernelStop;
  if(previous)previous->next=scope->next;
  else native_doc_recalc_scopes=scope->next;
}
U0 NativeDocRecalcScopeClose(CNativeDocRecalcScope *scope)
{
  U32 irq=I386IrqSave;
  if(scope->task!=I386TaskSelf || scope->task->cleanup!=&NativeDocRecalcCleanup)
    KernelStop;
  NativeDocRecalcScopeRemove(scope);
  scope->task->cleanup=scope->previous_cleanup;
  I386IrqRestore(irq);
}
U0 NativeDocRecalcScopeRelease(CNativeDocRecalcScope *scope)
{
  CDC *dc=*scope->dc;
  I32 *depth=*scope->depth;
  U8 *tag=*scope->tag;
  *scope->dc=NULL;*scope->depth=NULL;*scope->tag=NULL;
  if(dc && dc->depth_buf==depth)dc->depth_buf=NULL;
  DCDel(dc);Free(depth);Free(tag);
  if(*scope->unlock) {
    *scope->unlock=FALSE;
    DocUnlock(scope->doc);
  }
}
U0 NativeDocRecalcCleanup(CI386Task *task)
{//Exit bypasses lexical catch bodies; drain this task's nested scopes first.
  CNativeDocRecalcScope *scope;
  U0 (*previous)(CI386Task *task);
  U32 irq;
  Bool found=FALSE,top=task->cleanup==&NativeDocRecalcCleanup;
  previous=NULL;
  while(TRUE) {
    irq=I386IrqSave;
    scope=native_doc_recalc_scopes;
    while(scope && scope->task!=task)scope=scope->next;
    if(!scope) {I386IrqRestore(irq);break;}
    found=TRUE;previous=scope->previous_cleanup;
    NativeDocRecalcScopeRemove(scope);
    I386IrqRestore(irq);
    NativeDocRecalcScopeRelease(scope);
  }
  //A newer cleanup wrapper may have invoked this hook through its own chain.
  if(top || found)task->cleanup=previous;
  if(found && previous && previous!=&NativeDocRecalcCleanup)(*previous)(task);
}
#define DOC_RECALC_SCOPE_LOCAL CNativeDocRecalcScope native_recalc_scope
#define DOC_RECALC_SCOPE_OPEN NativeDocRecalcScopeOpen(&native_recalc_scope,doc,&unlock,&dc,&depth_buf,&new_tag)
#define DOC_RECALC_SCOPE_CLOSE NativeDocRecalcScopeClose(&native_recalc_scope)
