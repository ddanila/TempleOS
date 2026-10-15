class CNativeGraphicsScope:CNativeRenderScope {
  CDC **alias;
  Bool *lease;
  CI386Task **presenter;
  Bool owns_lease;
};
extern Bool NativeGraphicsReady();
U0 NativeGraphicsScopeReleaseLease(CNativeGraphicsScope *scope)
{
  U32 irq=I386IrqSave;
  if(scope->owns_lease) {
    if(!scope->lease || !scope->presenter || *scope->presenter!=scope->task)
      KernelStop;
    *scope->presenter=NULL;*scope->lease=FALSE;scope->owns_lease=FALSE;
  }
  I386IrqRestore(irq);
}
U0 NativeGraphicsScopeRelease(CNativeRenderScope *base)
{
  CNativeGraphicsScope *scope=base;
  CDC *alias=NULL;
  if(scope->alias) {alias=*scope->alias;*scope->alias=NULL;}
  DCDel(alias);
  NativeGraphicsScopeReleaseLease(scope);
}
U0 NativeGraphicsScopeOpen(CNativeGraphicsScope *scope,CDC **alias,Bool *lease,
  CI386Task **presenter)
{
  scope->alias=alias;scope->lease=lease;scope->presenter=presenter;
  scope->owns_lease=FALSE;
  NativeRenderScopeOpen(scope,&NativeGraphicsScopeRelease);
}
Bool NativeGraphicsScopeAcquire(CNativeGraphicsScope *scope)
{//Foreign callers wait cooperatively. Same-task recursion cannot make progress.
  U32 irq;
  if(!scope->lease || !scope->presenter)KernelStop;
  while(TRUE) {
    irq=I386IrqSave;
    if(!NativeGraphicsReady) {I386IrqRestore(irq);return FALSE;}
    if(!*scope->lease) {
      *scope->presenter=scope->task;*scope->lease=TRUE;scope->owns_lease=TRUE;
      I386IrqRestore(irq);return TRUE;
    }
    if(*scope->presenter==scope->task) {I386IrqRestore(irq);return FALSE;}
    I386IrqRestore(irq);
    Yield;
  }
}
#define GRAPHICS_FRAME_SCOPE_LOCAL CNativeGraphicsScope native_graphics_scope
#define GRAPHICS_FRAME_SCOPE_OPEN NativeGraphicsScopeOpen(&native_graphics_scope,&alias,NULL,NULL)
#define GRAPHICS_FRAME_SCOPE_CLOSE NativeRenderScopeClose(&native_graphics_scope)
