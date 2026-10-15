class CNativeDocDeleteScope:CNativeRenderScope {
  CDoc **doc;
  CI386Task *retained_owner;
  Bool *unlock,*disposed;
};
U0 NativeDocDeleteOwnerRelease(CNativeDocDeleteScope *scope)
{
  CI386Task *owner=scope->retained_owner;
  U32 irq;
  if(!owner)return;
  irq=I386IrqSave;scope->retained_owner=NULL;
  if(!owner->lifetime_refs)KernelStop;
  owner->lifetime_refs--;I386IrqRestore(irq);
}
U0 NativeDocDeleteRelease(CNativeRenderScope *base)
{
  CNativeDocDeleteScope *scope=base;
  CDoc *doc;
  if(*scope->unlock) {
    *scope->unlock=FALSE;DocUnlock(*scope->doc);
  }
  if(*scope->disposed) {
    *scope->disposed=FALSE;doc=*scope->doc;*scope->doc=NULL;Free(doc);
  }
  NativeDocDeleteOwnerRelease(scope);
}
U0 NativeDocDeletePrepareExit(CNativeRenderScope *base)
{
  CNativeDocDeleteScope *scope=base;
  if(!scope->retained_owner)return;
  //Exit abandons this deletion. Descendants may now destroy the target heap;
  //late cleanup must not dereference it after dropping the storage reference.
  NativeDocDeleteRelease(base);
  *scope->doc=NULL;*scope->unlock=FALSE;*scope->disposed=FALSE;
  scope->resource=NULL;scope->resource_owner=scope->window_owner=NULL;
  scope->retiring_resource=FALSE;
}
U0 NativeDocDeleteOpen(CNativeDocDeleteScope *scope,CDoc **doc,
  Bool *unlock,Bool *disposed)
{
  CNativeRenderScope *item=native_render_scopes;
  CI386Task *owner;
  U32 irq;
  if(NativeRenderResourceRetiring(*doc))throw('DocBusy',TRUE);
  while(item) {
    if(item->task==I386TaskSelf && item->resource==*doc)throw('DocBusy',TRUE);
    item=item->next;
  }
  owner=(*doc)->mem_task;
  irq=I386IrqSave;
  if(!TaskValidate(owner) || owner!=I386TaskSelf &&
      (NativeRenderOwnerClosing(owner)||owner->lifetime_refs==0xFFFFFFFF)) {
    I386IrqRestore(irq);throw('DocGone',TRUE);
  }
  scope->doc=doc;scope->unlock=unlock;scope->disposed=disposed;
  scope->retained_owner=NULL;
  if(owner!=I386TaskSelf) {
    //Allow logical owner exit while keeping its task/heap storage allocated.
    //A render-owner dependency would instead kill/wait for this deleter.
    owner->lifetime_refs++;scope->retained_owner=owner;
  }
  NativeRenderScopeOpen(scope,&NativeDocDeleteRelease);
  scope->prepare_exit=&NativeDocDeletePrepareExit;
  if(owner==I386TaskSelf)scope->resource_owner=owner;
  //The destructor uses document allocations, not the window task. Pinning the
  //window here creates a cycle when resource retirement stops that editor:
  //the editor would wait for this deleting frame while it waits for the editor.
  scope->resource=*doc;scope->retiring_resource=TRUE;
  I386IrqRestore(irq);
}
public U0 DocDel(CDoc *doc)
{
  CNativeDocDeleteScope scope;
  Bool unlock=FALSE,disposed=FALSE,registered=FALSE;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL)return;
  try {
    NativeDocDeleteOpen(&scope,&doc,&unlock,&disposed);registered=TRUE;
    NativeRenderRetire(NULL,doc);
    unlock=DocLock(doc);NativeDocRstUnlocked(doc,TRUE);
    doc->doc_signature=0;
    Free(doc->find_replace);doc->find_replace=NULL;
    Free(doc->dollar_buf);doc->dollar_buf=NULL;disposed=TRUE;
    NativeDocDeleteRelease(&scope);
    NativeRenderScopeClose(&scope);
  } catch {
    if(registered) {
      NativeDocDeleteRelease(&scope);
      NativeRenderScopeClose(&scope);
    }
  }
}
