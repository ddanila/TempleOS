#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Message.HH"
public Bool I386MsgInit(CI386MsgQueue *queue,CI386Scheduler *scheduler)
{//Zeroed persistent record. No reinitialization while readers might retain it.
  U32 flags=I386IrqSave;
  if (!queue || queue->scheduler || !scheduler || !scheduler->root) {
    I386IrqRestore(flags); return FALSE;
  }
  queue->scheduler=scheduler; queue->waiter=0; queue->read_cancelled=0;
  queue->recipient=0;
  queue->head=0; queue->count=0; queue->closed=0;
  I386IrqRestore(flags); return TRUE;
}
U0 I386MsgReady(CI386MsgQueue *queue)
{//IF clear. A public flag wait need not have a private queue-reader waiter.
  if(queue->recipient) queue->recipient->task_flags&=~(1<<TASKf_AWAITING_MSG);
  if(queue->waiter) {
    queue->waiter->task_flags&=~(1<<TASKf_AWAITING_MSG);
    if(queue->waiter->blocked) I386SchedWake(queue->scheduler,queue->waiter);
  }
}
public Bool I386MsgSend(CI386MsgQueue *queue,I64 type,I64 arg1,I64 arg2)
{//Bounded nonblocking send; caller owns retry/drop policy when full.
  U32 flags=I386IrqSave;
  CI386Message *slot;
  if (!queue || !queue->scheduler || queue->closed || queue->count==16 || type<1 || type>63) {
    I386IrqRestore(flags); return FALSE;
  }
  if (queue->recipient && queue->recipient->finished) {
    I386IrqRestore(flags); return FALSE;
  }
  slot=&queue->messages[(queue->head+queue->count)&15];
  slot->type=type; slot->arg1=arg1; slot->arg2=arg2;
  queue->count++;
  I386MsgReady(queue);
  I386IrqRestore(flags); return TRUE;
}
public I64 I386MsgRead(CI386MsgQueue *queue,CI386Message *message,U64 mask=~1,Bool wait=TRUE)
{//Task context. Discard unmatched messages like ScanMsg; one pending reader.
  U32 flags=I386IrqSave;
  CI386Scheduler *s;
  CI386Task *self;
  CI386Message *slot;
  I64 type;
  Bool cancelled=FALSE;
  if (!queue || !queue->scheduler || !message || !(mask&~1)) {
    I386IrqRestore(flags); return 0;
  }
  s=queue->scheduler; self=s->current;
  if (!self || (queue->recipient && queue->recipient!=self) ||
      (queue->waiter && queue->waiter!=self)) {
    I386IrqRestore(flags); return 0;
  }
  while (TRUE) {
    while (queue->count) {
      slot=&queue->messages[queue->head];
      queue->head=(queue->head+1)&15; queue->count--;
      type=slot->type;
      if (mask&(1<<type)) {
        message->type=type; message->arg1=slot->arg1; message->arg2=slot->arg2;
        if(queue->waiter==self) self->task_flags&=~(1<<TASKf_AWAITING_MSG);
        queue->waiter=0; queue->read_cancelled=0;
        I386IrqRestore(flags); return type;
      }
    }
    if (!wait || queue->closed || self==s->root) {
      if(queue->waiter==self) self->task_flags&=~(1<<TASKf_AWAITING_MSG);
      queue->waiter=0; queue->read_cancelled=0; I386IrqRestore(flags); return 0;
    }
    queue->waiter=self; queue->read_cancelled=&cancelled;
    self->task_flags|=1<<TASKf_AWAITING_MSG;
    if (!I386SchedBlock(s)) {
      self->task_flags&=~(1<<TASKf_AWAITING_MSG);
      queue->waiter=0; queue->read_cancelled=0; I386IrqRestore(flags); return 0;
    }
    //Cancellation detaches the registration; the queue may have been reused.
    if(cancelled) { I386IrqRestore(flags); return 0; }
  }
}
public Bool I386MsgClose(CI386MsgQueue *queue)
{//Reject future sends, preserve queued messages, wake the reader to drain/finish.
  U32 flags=I386IrqSave;
  if (!queue || !queue->scheduler || queue->closed) {
    I386IrqRestore(flags); return FALSE;
  }
  queue->closed=1;
  I386MsgReady(queue);
  I386IrqRestore(flags); return TRUE;
}
public Bool I386MsgAttach(CI386MsgQueue *queue,CI386Task *task)
{//Attach an empty initialized queue; a live task may have only one inbox.
  U32 flags=I386IrqSave;
  if (!queue || !queue->scheduler || queue->closed || queue->count || queue->waiter ||
      queue->recipient || !task || task->owner!=queue->scheduler || task->messages ||
      task->finished || task->finishing) {
    I386IrqRestore(flags); return FALSE;
  }
  queue->recipient=task; task->messages=queue;
  I386IrqRestore(flags); return TRUE;
}
public Bool I386MsgDetach(CI386MsgQueue *queue)
{//Closed inbox only: its own task, or another task after recipient completion.
  U32 flags=I386IrqSave;
  CI386Task *task;
  if (!queue || !queue->scheduler || !queue->closed || queue->waiter || !queue->recipient) {
    I386IrqRestore(flags); return FALSE;
  }
  task=queue->recipient;
  if (task->messages!=queue || (!task->finished && task!=queue->scheduler->current)) {
    I386IrqRestore(flags); return FALSE;
  }
  task->messages=0; queue->recipient=0;
  queue->head=0; queue->count=0;
  I386IrqRestore(flags); return TRUE;
}
public Bool I386TaskMsgSend(CI386Task *task,I64 type,I64 arg1,I64 arg2)
{
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if (task && task->owner && !task->finished && task->messages)
    result=I386MsgSend(task->messages,type,arg1,arg2);
  I386IrqRestore(flags); return result;
}

public Bool I386MsgCancelRead(CI386MsgQueue *queue,CI386Task *task)
{//Single CPU: wake cannot switch, and IRQs stay masked until detachment.
  U32 flags=I386IrqSave;
  Bool ok=FALSE;
  if(!queue || !queue->scheduler || !task || task->owner!=queue->scheduler ||
      task->finished || queue->waiter!=task || !queue->read_cancelled) goto msg_cancel_done;
  if(task->blocked && !I386SchedWake(queue->scheduler,task)) goto msg_cancel_done;
  *queue->read_cancelled=TRUE;
  queue->waiter=0; queue->read_cancelled=0;
  task->task_flags&=~(1<<TASKf_AWAITING_MSG);
  ok=TRUE;
msg_cancel_done:
  I386IrqRestore(flags); return ok;
}
