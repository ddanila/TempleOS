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
public Bool I386TaskBreakPoll()
{
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  if(!I386TaskBreakLive(task) || task->owner->current!=task ||
      !(task->task_flags&(1<<TASKf_PENDING_BREAK)) ||
      task->task_flags&(1<<TASKf_BREAK_LOCKED|1<<TASKf_BREAK_TO_SHIFT_ESC) ||
      task->blocked || task->wait || task->io_locks || task->lifetime_refs ||
      task->compiler_busy || task->active_controls || task->compiler_cleanup_failed ||
      task->messages) {
    I386IrqRestore(flags); return FALSE;
  }
  task->task_flags&=~(1<<TASKf_PENDING_BREAK);
  task->wake_jiffy=0;
  I386IrqRestore(flags);
  throw('Break');
  return FALSE;
}
