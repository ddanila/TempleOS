class CNativeDocDeleteScope:CNativeRenderScope {
  CDoc **doc;
  Bool *unlock,*disposed;
};
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
}
U0 NativeDocDeleteOpen(CNativeDocDeleteScope *scope,CDoc **doc,
  Bool *unlock,Bool *disposed)
{
  CNativeRenderScope *item=native_render_scopes;
  if(NativeRenderResourceRetiring(*doc))throw('DocBusy',TRUE);
  while(item) {
    if(item->task==I386TaskSelf && item->resource==*doc)throw('DocBusy',TRUE);
    item=item->next;
  }
  if((*doc)->mem_task!=Fs && NativeRenderOwnerClosing((*doc)->mem_task))
    throw('DocGone',TRUE);
  scope->doc=doc;scope->unlock=unlock;scope->disposed=disposed;
  NativeRenderScopeOpen(scope,&NativeDocDeleteRelease);
  scope->resource_owner=(*doc)->mem_task;
  if(TaskValidate((*doc)->win_task))scope->window_owner=(*doc)->win_task;
  scope->resource=*doc;scope->retiring_resource=TRUE;
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
