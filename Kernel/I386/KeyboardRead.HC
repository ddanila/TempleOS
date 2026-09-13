#include "/Kernel/I386/KeyboardRead.HH"
#include "/Kernel/I386/Cpu.HH"
public Bool I386KeyboardReadInit(CI386KeyboardReader *reader,CI386KbcInput *input)
{//One persistent reader per input stream; input association initially zero.
  U32 flags=I386IrqSave;
  if (!reader || reader->input || !input || !input->scheduler) {
    I386IrqRestore(flags); return FALSE;
  }
  I386KeyboardReset(&reader->state);
  reader->input=input; reader->losses=0;
  I386IrqRestore(flags); return TRUE;
}
Bool I386KeyboardReadLost(CI386KeyboardReader *reader)
{//IF clear, exclusive reader. Discard the ambiguous backlog after a loss/reset.
  U32 losses=reader->input->queue.dropped;
  U8 data,status;
  if (losses==reader->losses && losses!=0xFFFFFFFF) return FALSE;
  while (I386KbcQueueGet(&reader->input->queue,&data,&status)) {}
  I386KeyboardReset(&reader->state); reader->losses=losses;
  return TRUE;
}
public I64 I386KeyboardRead(CI386KeyboardReader *reader,CI386KeyEvent *event,Bool wait=TRUE)
{//1 event, 0 unavailable, -1 discontinuity/invalid input. Task context only.
  U32 flags=I386IrqSave;
  U8 data,status;
  I64 result;
  if (!reader || !reader->input || !event) { I386IrqRestore(flags); return -1; }
  if (reader->input->waiter && reader->input->waiter!=reader->input->scheduler->current) {
    I386IrqRestore(flags); return 0;
  }
  while (TRUE) {
    if (I386KeyboardReadLost(reader)) { I386IrqRestore(flags); return -1; }
    if (!I386KbcInputRead(reader->input,&data,&status,wait)) {
      I386IrqRestore(flags); return 0;
    }
    //The raw read may have blocked while the IRQ producer filled its queue.
    if (I386KeyboardReadLost(reader)) { I386IrqRestore(flags); return -1; }
    result=I386KeyboardFeed(&reader->state,data,status,event);
    if (result) { I386IrqRestore(flags); return result; }
  }
}
