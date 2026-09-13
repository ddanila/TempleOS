#include "/Kernel/I386/Focus.HH"
#include "/Kernel/I386/Cpu.HH"
public Bool I386FocusSet(CI386Scheduler *scheduler,CI386Task *task)
{//One selected recipient per scheduler. Null explicitly clears focus.
  U32 flags=I386IrqSave;
  if (!scheduler || !scheduler->root) { I386IrqRestore(flags); return FALSE; }
  if (task && (task->owner!=scheduler || task->finished || task->finishing ||
      !task->messages || task->messages->closed)) {
    I386IrqRestore(flags); return FALSE;
  }
  scheduler->focus=task;
  I386IrqRestore(flags); return TRUE;
}
public Bool I386FocusMsgSend(CI386Scheduler *scheduler,I64 type,I64 arg1,I64 arg2)
{//Selection and publication share one interrupt mask; send never switches tasks.
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if (scheduler && scheduler->root && scheduler->focus)
    result=I386TaskMsgSend(scheduler->focus,type,arg1,arg2);
  I386IrqRestore(flags); return result;
}
