#ifndef I386_PUBLIC_BREAK_POLL_CORE_INCLUDED
#define I386_PUBLIC_BREAK_POLL_CORE_INCLUDED
//A public foreign unlock already consumed the public pending bit. Its action
//runs on the target only after native waits and temporary borrows have ended.
Bool I386PublicBreakPoll(CI386Task *task)
{
  U32 irq;
  U0 (*callback)();
  if(!task || !task->public_break)return FALSE;
  irq=I386IrqSave;callback=0;
  if(task && task->owner && task->owner->current==task &&
      !task->finished && !task->finishing && task->public_break &&
      !task->blocked && !task->wait && !task->io_locks && !task->messages &&
      !task->compiler_busy && !task->compiler_cleanup_failed &&
      task->lifetime_refs==task->active_controls+task->inherited_refs) {
    callback=task->public_break;task->public_break=0;
  }
  I386IrqRestore(irq);
  if(callback){(*callback)();return TRUE;}
  return FALSE;
}
#endif
