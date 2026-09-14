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
  CI386Sleeper waiter,*node,*previous;
  if(!queue || !queue->scheduler || ticks<0) { I386IrqRestore(flags); return 0; }
  s=queue->scheduler;
  if(!s->current || s->current->owner!=s || s->current->finished) {
    I386IrqRestore(flags); return 0;
  }
  if(!ticks) { I386IrqRestore(flags); return 1; }
  if(s->current==s->root || s->current->blocked) { I386IrqRestore(flags); return 0; }
  waiter.task=s->current; waiter.remaining=ticks; waiter.queued=1;
  waiter.next=queue->head; queue->head=&waiter;
  //A generic Wake may be spurious. Keep the stack record live until its tick expires.
  while(waiter.queued) {
    if(!I386SchedBlock(s)) {
      previous=0; node=queue->head;
      while(node && node!=&waiter) { previous=node; node=node->next; }
      if(node) {
        if(previous) previous->next=node->next;
        else queue->head=node->next;
      }
      I386IrqRestore(flags); return 0;
    }
  }
  I386IrqRestore(flags); return 1;
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
