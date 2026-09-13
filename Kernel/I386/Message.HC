#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Message.HH"
public Bool I386MsgInit(CI386MsgQueue *queue,CI386Scheduler *scheduler)
{//Zeroed persistent record. No reinitialization while readers might retain it.
  U32 flags=I386IrqSave;
  if (!queue || queue->scheduler || !scheduler || !scheduler->root) {
    I386IrqRestore(flags); return FALSE;
  }
  queue->scheduler=scheduler; queue->waiter=0;
  queue->head=0; queue->count=0; queue->closed=0;
  I386IrqRestore(flags); return TRUE;
}
public Bool I386MsgSend(CI386MsgQueue *queue,I64 type,I64 arg1,I64 arg2)
{//Bounded nonblocking send; caller owns retry/drop policy when full.
  U32 flags=I386IrqSave;
  CI386Message *slot;
  if (!queue || !queue->scheduler || queue->closed || queue->count==16 || type<1 || type>63) {
    I386IrqRestore(flags); return FALSE;
  }
  slot=&queue->messages[(queue->head+queue->count)&15];
  slot->type=type; slot->arg1=arg1; slot->arg2=arg2;
  queue->count++;
  if (queue->waiter) I386SchedWake(queue->scheduler,queue->waiter);
  I386IrqRestore(flags); return TRUE;
}
public I64 I386MsgRead(CI386MsgQueue *queue,CI386Message *message,U64 mask=~1,Bool wait=TRUE)
{//Task context. Discard unmatched messages like ScanMsg; one pending reader.
  U32 flags=I386IrqSave;
  CI386Scheduler *s;
  CI386Task *self;
  CI386Message *slot;
  I64 type;
  if (!queue || !queue->scheduler || !message || !(mask&~1)) {
    I386IrqRestore(flags); return 0;
  }
  s=queue->scheduler; self=s->current;
  if (!self || (queue->waiter && queue->waiter!=self)) {
    I386IrqRestore(flags); return 0;
  }
  while (TRUE) {
    while (queue->count) {
      slot=&queue->messages[queue->head];
      queue->head=(queue->head+1)&15; queue->count--;
      type=slot->type;
      if (mask&(1<<type)) {
        message->type=type; message->arg1=slot->arg1; message->arg2=slot->arg2;
        queue->waiter=0;
        I386IrqRestore(flags); return type;
      }
    }
    if (!wait || queue->closed || self==s->root) {
      queue->waiter=0; I386IrqRestore(flags); return 0;
    }
    queue->waiter=self;
    if (!I386SchedBlock(s)) {
      queue->waiter=0; I386IrqRestore(flags); return 0;
    }
  }
}
public Bool I386MsgClose(CI386MsgQueue *queue)
{//Reject future sends, preserve queued messages, wake the reader to drain/finish.
  U32 flags=I386IrqSave;
  if (!queue || !queue->scheduler || queue->closed) {
    I386IrqRestore(flags); return FALSE;
  }
  queue->closed=1;
  if (queue->waiter) I386SchedWake(queue->scheduler,queue->waiter);
  I386IrqRestore(flags); return TRUE;
}
