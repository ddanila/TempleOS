#include "/Kernel/I386/TaskBreakRequestCore.HC"
#include "/Kernel/I386/PublicBreakPollCore.HC"
public Bool I386TaskBreakPoll()
{
  CI386Task *task=I386TaskSelf;
  U32 flags;
  I386PublicBreakPoll(task);
  flags=I386IrqSave;
  //Inherited child state and code references prevent retirement, not a caught
  //exception on this live task. Busy operations have their own guards below.
  if(!I386TaskBreakLive(task) || task->owner->current!=task ||
      !(task->task_flags&(1<<TASKf_PENDING_BREAK)) ||
      task->task_flags&(1<<TASKf_BREAK_LOCKED|1<<TASKf_BREAK_TO_SHIFT_ESC) ||
      task->blocked || task->wait || task->io_locks ||
      task->lifetime_refs!=task->inherited_refs ||
      task->compiler_busy || task->active_controls || task->compiler_cleanup_failed ||
      task->messages) {
    I386IrqRestore(flags); return FALSE;
  }
  task->task_flags&=~(1<<TASKf_PENDING_BREAK);
  task->wake_jiffy=0;
  I386IrqRestore(flags);
#ifdef I386_TASK_BREAK_RELEASE
  I386_TASK_BREAK_RELEASE
#endif
  throw('Break');
  return FALSE;
}
