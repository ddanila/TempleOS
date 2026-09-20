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
public Bool I386KbcInputRead(CI386KbcInput *input,U8 *data,U8 *status,Bool wait=TRUE)
{//Task context, one pending reader. Outputs must not overlap the input record.
  U32 flags=I386IrqSave;
  CI386Scheduler *s;
  CI386Task *self;
  Bool cancelled=FALSE;
  if (!input || !input->scheduler || !data || !status || data==status) {
    I386IrqRestore(flags); return FALSE;
  }
  s=input->scheduler; self=s->current;
  if (!self || (input->waiter && input->waiter!=self)) {
    I386IrqRestore(flags); return FALSE;
  }
  while (!I386KbcQueueGet(&input->queue,data,status)) {
    if (!wait || self==s->root) { I386IrqRestore(flags); return FALSE; }
    input->waiter=self; input->read_cancelled=&cancelled;
    if (!I386SchedBlock(s)) {
      input->waiter=0; input->read_cancelled=0; I386IrqRestore(flags); return FALSE;
    }
    //A cancelled stream can be freed or handed to another reader before we run.
    if(cancelled) { I386IrqRestore(flags); return FALSE; }
  }
  input->waiter=0; input->read_cancelled=0;
  I386IrqRestore(flags); return TRUE;
}
