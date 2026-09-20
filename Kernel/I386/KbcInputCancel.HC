#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/KbcInput.HH"
public Bool I386KbcInputCancel(CI386KbcInput *input,CI386Task *task)
{//Retained caller code; input and scheduler remain owned by the kernel.
  U32 flags=I386IrqSave;
  Bool ok=FALSE;
  if(!input || !input->scheduler || !task || task->owner!=input->scheduler ||
      task->finished || input->waiter!=task || !input->read_cancelled) goto input_cancel_done;
  if(task->blocked && !I386SchedWake(input->scheduler,task)) goto input_cancel_done;
  *input->read_cancelled=TRUE;
  input->waiter=0; input->read_cancelled=0;
  ok=TRUE;
input_cancel_done:
  I386IrqRestore(flags); return ok;
}
