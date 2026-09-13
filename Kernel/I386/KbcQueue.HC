#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/KbcQueue.HH"
//Single CPU, live initialized storage, no NMI access. Fields are private.
public U0 I386KbcQueueInit(CI386KbcQueue *queue)
{//Reset only when no consumer is waiting for earlier input.
  U32 flags=I386IrqSave;
  if (queue) { queue->head=0; queue->count=0; queue->dropped=0; }
  I386IrqRestore(flags);
}
public Bool I386KbcQueuePut(CI386KbcQueue *queue,U8 data,U8 status)
{//Drop newest on overflow; retained bytes keep their original ordering/status.
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if (queue) {
    if (queue->count==64) {
      if (queue->dropped!=0xFFFFFFFF) queue->dropped++;
    } else {
      queue->bytes[(queue->head+queue->count)&63]=data|(status<<8);
      queue->count++; result=TRUE;
    }
  }
  I386IrqRestore(flags);
  return result;
}
public Bool I386KbcQueueGet(CI386KbcQueue *queue,U8 *data,U8 *status)
{//Output storage must be writable and outside the queue record.
  U32 flags=I386IrqSave;
  U16 value;
  Bool result=FALSE;
  if (queue && data && status && data!=status && queue->count) {
    value=queue->bytes[queue->head];
    queue->head=(queue->head+1)&63; queue->count--;
    *data=value; *status=value>>8; result=TRUE;
  }
  I386IrqRestore(flags);
  return result;
}
