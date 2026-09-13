#include "/Kernel/I386/Inbox.HH"
#include "/Kernel/I386/Cpu.HH"
public CI386OwnedInbox *I386InboxAlloc(CI386Task *task,CI386Heap *heap)
{//Task context. Allocation and attachment are atomic on the single CPU.
  U32 flags=I386IrqSave;
  CI386OwnedInbox *inbox;
  if (!task || !task->owner || task->finished || task->finishing || task->messages || !heap) {
    I386IrqRestore(flags); return 0;
  }
  inbox=I386HeapAlloc(heap,sizeof(CI386OwnedInbox),TRUE);
  if (!inbox) { I386IrqRestore(flags); return 0; }
  inbox->heap=heap; inbox->signature=0x494E3332;
  if (!I386MsgInit(&inbox->queue,task->owner) || !I386MsgAttach(&inbox->queue,task)) {
    I386HeapFree(heap,inbox); I386IrqRestore(flags); return 0;
  }
  I386IrqRestore(flags); return inbox;
}
public Bool I386InboxFree(CI386OwnedInbox *inbox)
{//Live owned record only; self cleanup or cleanup after recipient completion.
  U32 flags=I386IrqSave;
  CI386Task *task;
  Bool result;
  if (!inbox || inbox->signature!=0x494E3332 || !inbox->queue.scheduler ||
      inbox->queue.waiter || !inbox->queue.recipient ||
      I386HeapSize(inbox->heap,inbox)!=sizeof(CI386OwnedInbox)) {
    I386IrqRestore(flags); return FALSE;
  }
  task=inbox->queue.recipient;
  if (task->messages!=&inbox->queue || (!task->finished && task!=inbox->queue.scheduler->current)) {
    I386IrqRestore(flags); return FALSE;
  }
  if (!inbox->queue.closed) I386MsgClose(&inbox->queue);
  if (!I386MsgDetach(&inbox->queue)) { I386IrqRestore(flags); return FALSE; }
  result=I386HeapFree(inbox->heap,inbox);
  I386IrqRestore(flags); return result;
}
