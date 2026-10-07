//Temporary bounded E9 diagnostics for the multiple-task ordering red.
#define I386_WIN_ORDER_TRACE 1
I64 native_window_trace_count;
U0 WinOrderTrace(U8 *phase,CTask *task)
{
  if(native_window_trace_count++>=64)return;
  KernelLog("WIN ORDER ");KernelLog(phase);KernelHex(task);
  if(task){KernelHex(task->next_task);KernelHex(task->last_task);}
  KernelLog("\n");
}
//Reorder public windows without changing private scheduler membership.
#define WIf_SELF_FOCUS 0
#define I386_WIN_CHILD_HEAD_DECLARED 1
CTask *WinOrderChildHead(CTask *task)
{
  return (&task->next_child_task)(U8 *)-offset(CTask.next_sibling_task);
}
U0 NativeWindowTaskRemove(CTask *task)
{
  if(!TaskValidate(task)||!task->next_task||!task->last_task||
      task==sys_winmgr_task)throw('WinTask',TRUE);
  task->last_task->next_task=task->next_task;
  task->next_task->last_task=task->last_task;
  task->next_task=task->last_task=NULL;
}
U0 NativeWindowTaskInsert(CTask *task,CTask *pred)
{
  if(!TaskValidate(task)||!TaskValidate(pred)||task->next_task||task->last_task||
      !pred->next_task||!pred->last_task)throw('WinTask',TRUE);
  task->next_task=pred;task->last_task=pred->last_task;
  pred->last_task->next_task=task;pred->last_task=task;
}
#define TaskQueRem NativeWindowTaskRemove
#define TaskQueIns NativeWindowTaskInsert
#define WinToTop NativeWinToTop
#include "/Adam/WinOrderCore.HC"
