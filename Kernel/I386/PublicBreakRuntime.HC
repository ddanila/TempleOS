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
