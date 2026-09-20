#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/KbcInput.HH"
public Bool I386KbcInputInit(CI386KbcInput *input,CI386Scheduler *scheduler)
{//Zeroed persistent record, initialized scheduler. No reset of active streams.
  U32 flags=I386IrqSave;
  if (!input || input->scheduler || !scheduler || !scheduler->root) {
    I386IrqRestore(flags); return FALSE;
  }
  I386KbcQueueInit(&input->queue);
  input->scheduler=scheduler; input->waiter=0; input->read_cancelled=0;
  I386IrqRestore(flags); return TRUE;
}
public Bool I386KbcInputPut(CI386KbcInput *input,U8 data,U8 status)
{//IRQ-safe publication and wakeup; does not switch the interrupted task.
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if (input && input->scheduler) {
    result=I386KbcQueuePut(&input->queue,data,status);
    if (result && input->waiter) I386SchedWake(input->scheduler,input->waiter);
  }
  I386IrqRestore(flags); return result;
}
