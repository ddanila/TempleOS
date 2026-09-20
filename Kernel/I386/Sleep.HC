#include "/Kernel/I386/Sleep.HH"
public Bool I386SleepInit(CI386SleepQueue *queue,CI386Scheduler *s)
{
  U32 flags=I386IrqSave;
  if(!queue || queue->scheduler || queue->head || !s || !s->root) {
    I386IrqRestore(flags); return 0;
  }
  queue->scheduler=s;
  I386IrqRestore(flags); return 1;
}
public Bool I386SleepTicks(CI386SleepQueue *queue,I64 ticks)
{
  U32 flags=I386IrqSave;
  CI386Scheduler *s;
  CI386Sleeper waiter;
  CI386TaskWait registration;
  if(!queue || !queue->scheduler || ticks<0) { I386IrqRestore(flags); return 0; }
  s=queue->scheduler;
  if(!s->current || s->current->owner!=s || s->current->finished) {
    I386IrqRestore(flags); return 0;
  }
  if(!ticks) { I386IrqRestore(flags); return 1; }
  if(s->current==s->root || s->current->blocked || s->current->wait) { I386IrqRestore(flags); return 0; }
  registration.kind=I386_WAIT_SLEEP; registration.object=queue;
  registration.cancel=&I386SleepCancel; registration.cancelled=FALSE; registration.cancelling=FALSE;
  s->current->wait=&registration;
  waiter.task=s->current; waiter.remaining=ticks; waiter.queued=1;
  waiter.next=queue->head; queue->head=&waiter;
  //A generic Wake may be spurious. Keep the stack record live until its tick expires.
  while(waiter.queued) {
    if(!I386SchedBlock(s)) {
      I386SleepCancel(queue,waiter.task);
      waiter.task->wait=0;
      I386IrqRestore(flags); return 0;
    }
  }
  waiter.task->wait=0;
  I386IrqRestore(flags); return waiter.remaining==0;
}
public Bool I386SleepTick(CI386SleepQueue *queue)
{
  CI386Sleeper *node,*next,*previous=0;
  CI386Scheduler *s;
  if(!queue || !queue->scheduler || (GetRFlags&0x200)) return 0;
  s=queue->scheduler; node=queue->head;
  while(node) {
    next=node->next;
    if(!node->queued || !node->task || node->task->owner!=s || node->task->finished) return 0;
    if(node->remaining) node->remaining--;
    if(!node->remaining) {
      if(node->task->blocked && !I386SchedWake(s,node->task)) return 0;
      if(previous) previous->next=next;
      else queue->head=next;
      node->queued=0;
    } else previous=node;
    node=next;
  }
  return 1;
}

public Bool I386SleepCancel(CI386SleepQueue *queue,CI386Task *task)
{//Wake cannot switch; detach the stack waiter before restoring IRQs.
  U32 flags=I386IrqSave;
  CI386Sleeper *node,*previous=0;
  Bool ok=FALSE;
  if(!queue || !queue->scheduler || !task || task->owner!=queue->scheduler ||
      task->finished) goto sleep_cancel_done;
  node=queue->head;
  while(node && node->task!=task) { previous=node; node=node->next; }
  if(!node || !node->queued || !node->remaining) goto sleep_cancel_done;
  if(task->blocked && !I386SchedWake(queue->scheduler,task)) goto sleep_cancel_done;
  if(previous) previous->next=node->next;
  else queue->head=node->next;
  node->next=0; node->queued=0;
  if(task->wait && task->wait->kind==I386_WAIT_SLEEP && task->wait->object==queue)
    task->wait->cancelled=TRUE;
  ok=TRUE;
sleep_cancel_done:
  I386IrqRestore(flags); return ok;
}
