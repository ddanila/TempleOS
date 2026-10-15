extern U0 RefreshRestoreCore(CTask *task,CDoc *doc,Bool old_idle,Bool old_full_refresh,
  Bool *idle_saved,Bool *full_saved);
class CNativeRefreshScope:CNativeRenderScope {
  CDoc *doc;
  Bool *old_idle,*old_full,*idle_saved,*full_saved;
};
U0 NativeRefreshRelease(CNativeRenderScope *base)
{
  CNativeRefreshScope *scope=base;
  RefreshRestoreCore(scope->task,scope->doc,*scope->old_idle,*scope->old_full,
    scope->idle_saved,scope->full_saved);
}
U0 NativeRefreshOpen(CNativeRefreshScope *scope,CDoc *doc,Bool *old_idle,
  Bool *old_full,Bool *idle_saved,Bool *full_saved)
{
  scope->doc=doc;scope->old_idle=old_idle;scope->old_full=old_full;
  scope->idle_saved=idle_saved;scope->full_saved=full_saved;
  NativeRenderScopeOpen(scope,&NativeRefreshRelease);
  if(doc) {
    if(doc->doc_signature!=DOC_SIGNATURE_VAL)throw('DocGone',TRUE);
    NativeRenderScopeBorrow(scope,doc->mem_task,I386TaskSelf,doc);
  }
}
U0 NativeRefreshSleep(I64 ms) { (*native_window_sleep)(ms); }
#define REFRESH_SLEEP NativeRefreshSleep
#define REFRESH_JIFFIES NativeJiffies()
#define REFRESH_SCOPE_LOCAL CNativeRefreshScope native_refresh_scope
#define REFRESH_SCOPE_OPEN NativeRefreshOpen(&native_refresh_scope,old_doc,&old_idle,&old_full_refresh,&idle_saved,&full_saved)
#define REFRESH_SCOPE_RELEASE NativeRefreshRelease(&native_refresh_scope)
#define REFRESH_SCOPE_CLOSE NativeRenderScopeClose(&native_refresh_scope)
#include "/Adam/RefreshCore.HC"
