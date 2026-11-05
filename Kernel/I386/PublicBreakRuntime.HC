//Original current-task Break policy over the retained message/drive services.
U0 NativeBreak()
{
  CI386Task *task=I386TaskSelf;
  if(task->task_flags&(1<<TASKf_BREAK_TO_SHIFT_ESC))
    (*native_break_message)(MSG_KEY_DOWN,CH_SHIFT_ESC,0x20100000201,0);
  else {
    task->wake_jiffy=0;
    NativeTaskRstAwaitingMsg(task);
    DrvsRelease;BlkDevsRelease;
    (*native_servant_flush)(task);
    throw('Break');
  }
}

Bool NativeBreakLock(CTask *task=0)
{
  U32 irq=I386IrqSave;
  Bool result;
  if(!task)task=Fs;
  result=!(task->task_flags&(1<<TASKf_BREAK_LOCKED));
  task->task_flags|=1<<TASKf_BREAK_LOCKED;
  I386IrqRestore(irq);return result;
}
Bool NativeBreakUnlock(CTask *task=0)
{
  CI386Task *target;
  U32 irq=I386IrqSave;
  Bool result,deliver=FALSE;
  if(!task)task=Fs;
  result=(task->task_flags&(1<<TASKf_BREAK_LOCKED))!=0;
  task->task_flags&=~(1<<TASKf_BREAK_LOCKED);
  if(task->task_flags&(1<<TASKf_PENDING_BREAK)) {
    task->task_flags&=~(1<<TASKf_PENDING_BREAK);
    if(task==I386TaskSelf){I386TaskSelf->public_break=0;deliver=TRUE;}
    else {
      //Preserve public descriptor semantics even for a standalone CTask.
      task->rip=(&NativeBreak+0)(U64);
      target=(*native_break_target)(task);
      if(target)target->public_break=&NativeBreak;
    }
  }
  I386IrqRestore(irq);
  if(deliver)NativeBreak;
  return result;
}
