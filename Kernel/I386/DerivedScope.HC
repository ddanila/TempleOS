//Borrow the control owner before locking or invoking its derived callbacks.
extern U0 TaskWindowDerivedRelease(CTask *task,I64 flags,Bool *locked);
class CNativeDerivedScope:CNativeRenderScope {
  CTask *target;
  I64 flags;
  Bool *locked;
  U0 (*invalidate)();
};
U0 NativeDerivedRelease(CNativeRenderScope *base)
{
  CNativeDerivedScope *scope=base;
  if(*scope->locked && scope->invalidate &&
      Bt(&scope->target->display_flags,DISPLAYf_SHOW)) (*scope->invalidate)();
  TaskWindowDerivedRelease(scope->target,scope->flags,scope->locked);
}
U0 NativeDerivedOpen(CNativeDerivedScope *scope,CTask *task,I64 flags,
  Bool *locked,U0 (*invalidate)())
{
  scope->target=task;scope->flags=flags;scope->locked=locked;
  scope->invalidate=invalidate;
  NativeRenderScopeOpen(scope,&NativeDerivedRelease);
  if(!task)throw('DocGone',TRUE);
  NativeRenderScopeBorrow(scope,task,task,NULL);
}
#define TASK_DERIVED_SCOPE_LOCAL CNativeDerivedScope native_derived_scope
#define TASK_DERIVED_SCOPE_OPEN NativeDerivedOpen(&native_derived_scope,task,flags,&locked,invalidate)
#define TASK_DERIVED_SCOPE_CLOSE NativeRenderScopeClose(&native_derived_scope)
#include "/Kernel/TaskWindowCore.HC"
U0 TaskDerivedValsUpdate(CTask *task=NULL,Bool update_z_buf=TRUE)
{
  if(!task)task=Fs;
  if(update_z_buf)TaskWindowDerivedCore(task,&CtrlsUpdate,&NativeWindowInvalidate);
  else TaskWindowDerivedCore(task,&CtrlsUpdate,NULL);
}
