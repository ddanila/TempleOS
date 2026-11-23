U0 (*native_ode_update)(CTask *task);
Bool NativeODEBind(U0 (*update)(CTask *task))
{
  if(!update || Fs!=*native_adam_task)return FALSE;
  if(native_ode_update && native_ode_update!=update)return FALSE;
  native_ode_update=update;
  return TRUE;
}
//The task identity remains valid while a derivative callback owns the update.
class CNativeODEScope:CNativeRenderScope {
  CTask *previous;
};
U0 NativeWindowODERelease(CNativeRenderScope *base)
{
  CNativeODEScope *scope=base;
  sys_task_being_scrn_updated=scope->previous;
}
U0 NativeWindowUpdateOneODE(CTask *task)
{
  CNativeODEScope scope;
  scope.previous=sys_task_being_scrn_updated;
  NativeRenderScopeOpen(&scope,&NativeWindowODERelease);
  try {
    NativeRenderScopeBorrow(&scope,task,task,NULL);
    sys_task_being_scrn_updated=task;
    (*native_ode_update)(task);
  } catch {
    if(TaskValidate(task) && Fs->except_ch!='DocGone' && Fs->except_ch!='WinAbort') {
      LBts(&task->win_inhibit,WIf_SELF_ODE);
      KernelLog("WINMGR task ODE exception\n");
    }
    Fs->catch_except=TRUE;
  }
  NativeWindowODERelease(&scope);
  NativeRenderScopeClose(&scope);
}
