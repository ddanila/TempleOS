//Cursor recalc can yield/throw/Exit: keep its window/document and owned lock live.
class CNativeWinCursorScope:CNativeRenderScope {
  CDoc **locked_doc;
  Bool *unlock;
};
U0 NativeWinCursorRelease(CNativeRenderScope *base)
{
  CNativeWinCursorScope *scope=base;
  if(*scope->unlock) {
    *scope->unlock=FALSE;DocUnlock(*scope->locked_doc);
  }
}
U0 NativeWinCursorOpen(CNativeWinCursorScope *scope,CTask *task,
  CDoc **locked_doc,Bool *unlock,Bool *opened)
{
  scope->locked_doc=locked_doc;scope->unlock=unlock;
  NativeRenderScopeOpen(scope,&NativeWinCursorRelease);*opened=TRUE;
  NativeRenderScopeBorrow(scope,task,task,NULL);
}
#define WIN_CURSOR_SCOPE_LOCAL CNativeWinCursorScope native_cursor_scope;Bool native_cursor_open=FALSE
#define WIN_CURSOR_SCOPE_OPEN NativeWinCursorOpen(&native_cursor_scope,task,&locked_doc,&unlock,&native_cursor_open)
#define WIN_CURSOR_SCOPE_DOC if(res)NativeRenderScopeBorrow(&native_cursor_scope,res->mem_task,task,res)
#define WIN_CURSOR_SCOPE_CLOSE if(native_cursor_open){native_cursor_open=FALSE;NativeRenderScopeClose(&native_cursor_scope);}
