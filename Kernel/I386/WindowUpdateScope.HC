extern U0 DrawCtrlsRelease(CTask *task,CDC **dc,Bool *expanded);
extern U0 GrTaskWinRelease(CTask *task,CDC **dc,CD3I64 *scroll,Bool *saved);
class CNativeControlScope:CNativeRenderScope {
  CTask *target;
  CDC **dc;
  Bool *expanded;
};
U0 NativeControlRelease(CNativeRenderScope *base)
{
  CNativeControlScope *scope=base;
  DrawCtrlsRelease(scope->target,scope->dc,scope->expanded);
}
U0 NativeControlOpen(CNativeControlScope *scope,CTask *task,CDC **dc,Bool *expanded)
{
  scope->target=task;scope->dc=dc;scope->expanded=expanded;
  NativeRenderScopeOpen(scope,&NativeControlRelease);
  if(!graphics_presenting || graphics_presenter!=I386TaskSelf)throw('Frame',TRUE);
  if(!task)throw('DocGone',TRUE);
  NativeRenderScopeBorrow(scope,task,task,NULL);
}
class CNativeWindowUpdateScope:CNativeRenderScope {
  CTask *target,*previous;
  CDC **dc;
  CD3I64 *scroll;
  Bool *saved,published;
};
U0 NativeWindowUpdateRelease(CNativeRenderScope *base)
{
  CNativeWindowUpdateScope *scope=base;
  GrTaskWinRelease(scope->target,scope->dc,scope->scroll,scope->saved);
  if(scope->published) {
    scope->published=FALSE;sys_task_being_scrn_updated=scope->previous;
  }
}
U0 NativeWindowUpdateOpen(CNativeWindowUpdateScope *scope,CTask *task,CDC **dc,
  CD3I64 *scroll,Bool *saved)
{
  scope->target=task;scope->dc=dc;scope->scroll=scroll;scope->saved=saved;
  scope->previous=sys_task_being_scrn_updated;scope->published=FALSE;
  NativeRenderScopeOpen(scope,&NativeWindowUpdateRelease);
  if(!task)throw('DocGone',TRUE);
  NativeRenderScopeBorrow(scope,task,task,NULL);
  sys_task_being_scrn_updated=task;scope->published=TRUE;
}
#define DRAW_CTRLS_SCOPE_LOCAL CNativeControlScope native_control_scope
#define DRAW_CTRLS_SCOPE_OPEN NativeControlOpen(&native_control_scope,task,&dc,&expanded)
#define DRAW_CTRLS_SCOPE_CLOSE NativeRenderScopeClose(&native_control_scope)
#define GR_TASK_WIN_SCOPE_LOCAL CNativeWindowUpdateScope native_window_scope
#define GR_TASK_WIN_SCOPE_OPEN NativeWindowUpdateOpen(&native_window_scope,task,&dc,&saved_scroll,&scroll_saved)
#define GR_TASK_WIN_SCOPE_CLOSE NativeWindowUpdateRelease(&native_window_scope);NativeRenderScopeClose(&native_window_scope)
#include "/Adam/Ctrls/DrawCtrlsCore.HC"
#include "/Adam/Gr/GrUpdateTaskWinCore.HC"
U0 GrUpdateTaskWin(CTask *task)
{//The frame owner supplies per-window failure policy and cancellation recovery.
  if(!graphics_presenting || graphics_presenter!=I386TaskSelf)throw('Frame',TRUE);
  GrUpdateTaskWinCore(task);
}
