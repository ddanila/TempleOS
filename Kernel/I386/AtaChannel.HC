#include "/Kernel/I386/AtaChannel.HH"
#include "/Kernel/I386/Cpu.HH"
#define I386_ATA_CHANNEL_MAGIC 0x41434831
class CI386AtaWaiter {
  CI386AtaWaiter *next;
  CI386Task *task;
  Bool queued;
};
Bool I386AtaChannelInit(CI386AtaChannel *channel,CI386Scheduler *scheduler,I64 number)
{
  U32 flags=I386IrqSave;
  Bool ok=FALSE;
  if(!channel || !scheduler || !scheduler->root || !scheduler->current || number<0 || number>1) goto channel_done;
  if(channel->poisoned || channel->signature || channel->scheduler || channel->owner || channel->head || channel->tail) goto channel_done;
  channel->scheduler=scheduler; channel->io=0x1F0; channel->control=0x3F6;
  if(number) { channel->io=0x170; channel->control=0x376; }
  channel->signature=I386_ATA_CHANNEL_MAGIC; ok=TRUE;
channel_done:
  I386IrqRestore(flags); return ok;
}
Bool I386AtaChannelAcquire(CI386AtaChannel *channel)
{
  U32 flags=I386IrqSave;
  CI386Scheduler *scheduler;
  CI386Task *task;
  CI386AtaWaiter waiter,*node,*previous;
  Bool ok=FALSE;
  if(!channel || channel->poisoned || channel->signature!=I386_ATA_CHANNEL_MAGIC || !(scheduler=channel->scheduler) ||
      !(task=scheduler->current) || task->owner!=scheduler || task->finished || task->finishing ||
      task->blocked || task->io_locks==0xFFFFFFFF || channel->owner==task) goto channel_done;
  if(!channel->owner) {
    if(channel->head || channel->tail) goto channel_done;
    channel->owner=task; task->io_locks++; ok=TRUE; goto channel_done;
  }
  if(task==scheduler->root) goto channel_done;
  waiter.next=0; waiter.task=task; waiter.queued=TRUE;
  if(channel->tail) channel->tail->next=&waiter;
  else channel->head=&waiter;
  channel->tail=&waiter;
  while(waiter.queued) {
    if(!I386SchedBlock(scheduler)) {
      previous=0; node=channel->head;
      while(node && node!=&waiter) { previous=node; node=node->next; }
      if(node) {
        if(previous) previous->next=node->next;
        else channel->head=node->next;
        if(channel->tail==node) channel->tail=previous;
      }
      goto channel_done;
    }
  }
  ok=channel->owner==task && task->io_locks!=0;
  if(ok && channel->poisoned) { I386AtaChannelRelease(channel); ok=FALSE; }
channel_done:
  I386IrqRestore(flags); return ok;
}
Bool I386AtaChannelRelease(CI386AtaChannel *channel)
{
  U32 flags=I386IrqSave;
  CI386Scheduler *scheduler;
  CI386Task *task,*next;
  CI386AtaWaiter *waiter;
  Bool ok=FALSE;
  if(!channel || channel->signature!=I386_ATA_CHANNEL_MAGIC || !(scheduler=channel->scheduler) ||
      !(task=scheduler->current) || channel->owner!=task || !task->io_locks) goto channel_done;
  waiter=channel->head;
  if(waiter) {
    next=waiter->task;
    if(!waiter->queued || !next || next->owner!=scheduler || next->finished || next->finishing ||
        next->io_locks==0xFFFFFFFF) goto channel_done;
    if(next->blocked && !I386SchedWake(scheduler,next)) goto channel_done;
    channel->head=waiter->next;
    if(!channel->head) channel->tail=0;
    channel->owner=next; next->io_locks++; waiter->queued=FALSE;
  } else {
    if(channel->tail) goto channel_done;
    channel->owner=0;
  }
  task->io_locks--; ok=TRUE;
channel_done:
  I386IrqRestore(flags); return ok;
}
Bool I386AtaChannelClose(CI386AtaChannel *channel)
{
  U32 flags=I386IrqSave;
  Bool ok=FALSE;
  if(channel && !channel->poisoned && channel->signature==I386_ATA_CHANNEL_MAGIC && !channel->owner && !channel->head && !channel->tail) {
    channel->signature=0; channel->scheduler=0; channel->io=0; channel->control=0; ok=TRUE;
  }
  I386IrqRestore(flags); return ok;
}
