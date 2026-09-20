#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/KbcInput.HH"
public Bool I386KbcInputRead(CI386KbcInput *input,U8 *data,U8 *status,Bool wait=TRUE)
{//Task context, one pending reader. Outputs must not overlap the input record.
  U32 flags=I386IrqSave;
  CI386Scheduler *s;
  CI386Task *self;
  CI386TaskWait registration;
  if (!input || !input->scheduler || !data || !status || data==status) {
    I386IrqRestore(flags); return FALSE;
  }
  s=input->scheduler; self=s->current;
  if (!self || self->wait || (input->waiter && input->waiter!=self)) {
    I386IrqRestore(flags); return FALSE;
  }
  registration.kind=I386_WAIT_KEYBOARD; registration.object=input;
  registration.cancel=&I386KbcInputCancel;
  registration.cancelled=FALSE; registration.cancelling=FALSE;
  while (!I386KbcQueueGet(&input->queue,data,status)) {
    if (!wait || self==s->root) { I386IrqRestore(flags); return FALSE; }
    self->wait=&registration;
    input->waiter=self; input->read_cancelled=&registration.cancelled;
    if (!I386SchedBlock(s)) {
      input->waiter=0; input->read_cancelled=0; self->wait=0; I386IrqRestore(flags); return FALSE;
    }
    //A cancelled stream can be freed or handed to another reader before we run.
    if(registration.cancelled) { self->wait=0; I386IrqRestore(flags); return FALSE; }
  }
  input->waiter=0; input->read_cancelled=0; self->wait=0;
  I386IrqRestore(flags); return TRUE;
}
