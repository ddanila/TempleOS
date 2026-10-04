//Public cancellation policy over the retained single-CPU task runtime.
Bool MemoryKill(CTask *task,Bool wait=TRUE,Bool just_break=FALSE)
{
  U32 irq=I386IrqSave;
  CHashExport *focus;
  if(!MemoryTaskValidate(task)) {
    I386IrqRestore(irq); return FALSE;
  }
  if(just_break) {
    I386IrqRestore(irq);
    if(task!=I386TaskSelf) {
      //Original Kill(other,,TRUE) invokes Break on the caller.
      if(I386TaskSelf->task_flags&(1<<TASKf_BREAK_TO_SHIFT_ESC))
        MemoryMsg(MSG_KEY_DOWN,0x1C,0x20100000201);
      else {
        I386TaskSelf->wake_jiffy=0;
        MemoryMessageWake(I386TaskSelf);
        MemoryFlushMsgs;
        throw('Break');
      }
      return FALSE;
    }
    irq=I386IrqSave;
    focus=HashFind("_SYS_FOCUS_TASK",I386TaskSelf->hash_table,HTT_EXPORT_SYS_SYM);
    if(focus) *focus->val(CTask **)=task;
    I386TaskSelf->task_flags|=1<<TASKf_PENDING_BREAK;
    I386IrqRestore(irq); return TRUE;
  }
  if(task==memory_root) {
    I386IrqRestore(irq); return FALSE;
  }
  //Do not rewrite wake/suspend flags for asynchronous requests. The scheduler
  //selects killed tasks and Exit owns callbacks, descendants and reclamation.
  task->task_flags|=1<<TASKf_KILL_TASK;
  I386IrqRestore(irq);
  if(wait) {
    do Yield;
    while(MemoryTaskValidate(task) && task->task_flags&(1<<TASKf_KILL_TASK));
  }
  return TRUE;
}
