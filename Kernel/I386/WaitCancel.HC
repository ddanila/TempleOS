#include "/Kernel/I386/Scheduler.HH"
#include "/Kernel/I386/Cpu.HH"
public Bool I386TaskCancelWait(CI386Task *task)
{//Cancellation releases the resource wait, not the caller's cleanup obligation.
  U32 flags=I386IrqSave;
  CI386TaskWait *wait;
  Bool result=FALSE;
  if(!task || !task->owner || task->finished || !(wait=task->wait) ||
      wait->cancelled || wait->cancelling || !wait->cancel || !wait->object) goto task_cancel_done;
  wait->cancelling=TRUE;
  result=(*wait->cancel)(wait->object,task);
  wait->cancelling=FALSE;
  if(result) wait->cancelled=TRUE;
task_cancel_done:
  I386IrqRestore(flags); return result;
}
