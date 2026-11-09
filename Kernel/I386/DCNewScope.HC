U0 NativeDCNewScopeRelease(CNativeRenderScope *base)
{//The constructor owns its unpublished header and each assigned allocation.
  CNativeDCNewScope *scope=base;
  CDC *dc;
  if(scope->context) {
    dc=*scope->context;*scope->context=NULL;
    if(dc){Free(dc->r);Free(dc->body);Free(dc);}
  }
}
U0 NativeDCNewScopeOpen(CNativeDCNewScope *scope,CDC **context)
{
  scope->context=context;
  NativeRenderScopeOpen(scope,&NativeDCNewScopeRelease);
}
