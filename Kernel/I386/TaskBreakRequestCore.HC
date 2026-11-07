#include "/Kernel/I386/TaskBreak.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/ExceptRuntime.HH"
Bool I386TaskBreakLive(CI386Task *task)
{
  return task && task->owner && !task->finished && !task->finishing;
}
public Bool I386TaskBreakLock(CI386Task *task)
{
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(I386TaskBreakLive(task)) {
    result=!(task->task_flags&(1<<TASKf_BREAK_LOCKED));
    task->task_flags|=1<<TASKf_BREAK_LOCKED;
  }
  I386IrqRestore(flags); return result;
}
public Bool I386TaskBreakRequest(CI386Task *task)
{//Record first; cancellation may only unlink/wake, never switch or deliver.
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(I386TaskBreakLive(task)) {
    task->task_flags|=1<<TASKf_PENDING_BREAK;
    if(!(task->task_flags&(1<<TASKf_BREAK_LOCKED|1<<TASKf_BREAK_TO_SHIFT_ESC))) {
      I386TaskCancelWait(task);
      task->wake_jiffy=0;
    }
    result=TRUE;
  }
  I386IrqRestore(flags); return result;
}
public Bool I386TaskBreakUnlock(CI386Task *task)
{//Deferred exception delivery occurs at an explicit current-task checkpoint.
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(I386TaskBreakLive(task)) {
    result=(task->task_flags&(1<<TASKf_BREAK_LOCKED))!=0;
    task->task_flags&=~(1<<TASKf_BREAK_LOCKED);
    if(task->task_flags&(1<<TASKf_PENDING_BREAK)) I386TaskBreakRequest(task);
  }
  I386IrqRestore(flags); return result;
}
