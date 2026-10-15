//Stack-resident render resources remain live until task cleanup runs.
class CNativeDocRecalcScope:CNativeRenderScope {
  CDoc *doc;
  Bool *unlock;
  CDC **dc;
  I32 **depth;
  U8 **tag;
};
U0 NativeDocRecalcScopeRelease(CNativeRenderScope *base)
{
  CNativeDocRecalcScope *scope=base;
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
U0 NativeDocRecalcScopeOpen(CNativeDocRecalcScope *scope,CDoc *doc,
  Bool *unlock,CDC **dc,I32 **depth,U8 **tag)
{
  scope->doc=doc;scope->unlock=unlock;scope->dc=dc;scope->depth=depth;scope->tag=tag;
  NativeRenderScopeOpen(scope,&NativeDocRecalcScopeRelease);
  NativeRenderScopeBorrow(scope,doc->mem_task,doc->win_task,doc);
}
#define DOC_RECALC_SCOPE_LOCAL CNativeDocRecalcScope native_recalc_scope
#define DOC_RECALC_SCOPE_OPEN NativeDocRecalcScopeOpen(&native_recalc_scope,doc,&unlock,&dc,&depth_buf,&new_tag)
#define DOC_RECALC_SCOPE_CLOSE NativeRenderScopeClose(&native_recalc_scope)
#define DOC_RECALC_SCOPE_LOCKED NativeRenderScopeBorrow(&native_recalc_scope,doc->mem_task,doc->win_task,doc)
