#include "/Kernel/I386/AtaChannel.HH"
#include "/Kernel/I386/Cpu.HH"
#define I386_ATA_CHANNEL_MAGIC 0x41434831
class CI386AtaWaiter {
  CI386AtaWaiter *next;
  CI386Task *task;
  Bool queued,retry;
};
Bool I386AtaChannelInit(CI386AtaChannel *channel,CI386Scheduler *scheduler,I64 number)
{
  U32 flags=I386IrqSave;
  Bool ok=FALSE;
  if(!channel || !scheduler || !scheduler->root || !scheduler->current || number<0 || number>1) goto channel_done;
  if(channel->poisoned || channel->signature || channel->scheduler || channel->owner || channel->head || channel->tail || channel->public_device || channel->public_unlock) goto channel_done;
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
  CI386TaskWait registration;
  Bool ok=FALSE,registered=FALSE,public_unlock=FALSE;
  CBlkDev *bd;
channel_acquire:
  if(!channel || channel->poisoned || channel->signature!=I386_ATA_CHANNEL_MAGIC || !(scheduler=channel->scheduler) ||
      !(task=scheduler->current) || task->owner!=scheduler || task->finished || task->finishing ||
      task->blocked || task->io_locks==0xFFFFFFFF || channel->owner==task) goto channel_done;
  bd=channel->public_device;
  if(bd && !channel->owner) {
    while(bd->lock_fwding) bd=bd->lock_fwding;
    //Borrowed file state must unwind normally if a waiting task is killed.
    //Use the raw scheduler while holding an I/O lifetime guard; public Yield
    //could otherwise exit with the caller's file-state borrow still live.
    task->io_locks++;
    while(Bt(&bd->locked_flags,BDlf_LOCKED) && bd->owning_task!=task) {
      if(task->task_flags&(1<<TASKf_KILL_TASK) || channel->poisoned) {
        task->io_locks--; goto channel_done;
      }
      SetRFlags(GetRFlags|0x200);
      I386SchedYield(scheduler);
      I386IrqSave;
    }
    task->io_locks--;
    if(channel->poisoned)goto channel_done;
    if(!Bt(&bd->locked_flags,BDlf_LOCKED)) {
      LBts(&bd->locked_flags,BDlf_LOCKED);bd->owning_task=task;public_unlock=TRUE;
    }
    //A bound controller's physical session is protected by this same target.
    if(channel->owner || channel->head || channel->tail) goto channel_done;
  }
  if(!channel->owner) {
    if(channel->head || channel->tail) goto channel_done;
    channel->owner=task;channel->public_unlock=public_unlock;
    task->io_locks++; ok=TRUE; goto channel_done;
  }
  if(task==scheduler->root || task->wait) goto channel_done;
  registration.kind=I386_WAIT_ATA; registration.object=channel;
  registration.cancel=&I386AtaChannelCancelWait;
  registration.cancelled=FALSE; registration.cancelling=FALSE;
  task->wait=&registration; registered=TRUE;
  waiter.next=0; waiter.task=task; waiter.queued=TRUE;waiter.retry=FALSE;
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
  if(waiter.retry) {
    task->wait=0;registered=FALSE;goto channel_acquire;
  }
  ok=channel->owner==task && task->io_locks!=0;
  if(ok && channel->poisoned) { I386AtaChannelRelease(channel); ok=FALSE; }
channel_done:
  if(!ok && public_unlock) {bd->owning_task=0;LBtr(&bd->locked_flags,BDlf_LOCKED);}
  if(registered) task->wait=0;
  I386IrqRestore(flags); return ok;
}
Bool I386AtaChannelRelease(CI386AtaChannel *channel)
{
  U32 flags=I386IrqSave;
  CI386Scheduler *scheduler;
  CI386Task *task,*next;
  CBlkDev *bd;
  CI386AtaWaiter *waiter;
  Bool ok=FALSE;
  if(!channel || channel->signature!=I386_ATA_CHANNEL_MAGIC || !(scheduler=channel->scheduler) ||
      !(task=scheduler->current) || channel->owner!=task || !task->io_locks) goto channel_done;
  waiter=channel->head;
  if(channel->public_device && !channel->public_unlock) {
    //The caller retains an outer public lock. Wake queued transactions to
    //retry without reserving the channel against that still-valid owner.
    while(waiter) {
      next=waiter->task;
      if(next->blocked && !I386SchedWake(scheduler,next)) goto channel_done;
      channel->head=waiter->next;
      waiter->retry=TRUE;waiter->queued=FALSE;waiter=channel->head;
    }
    channel->tail=0;
  }
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
  if(channel->public_unlock) {
    bd=channel->public_device;while(bd->lock_fwding)bd=bd->lock_fwding;
    bd->owning_task=channel->owner;
    if(!channel->owner) {
      LBtr(&bd->locked_flags,BDlf_LOCKED);channel->public_unlock=FALSE;
    }
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
    if(channel->public_device && Bt(&channel->public_device->locked_flags,BDlf_LOCKED)) {
      I386IrqRestore(flags);return FALSE;
    }
    channel->public_device=0;channel->public_unlock=FALSE;
    channel->signature=0; channel->scheduler=0; channel->io=0; channel->control=0; ok=TRUE;
  }
  I386IrqRestore(flags); return ok;
}
Bool I386AtaChannelCancelWait(CI386AtaChannel *channel,CI386Task *task)
{//Keep IRQs masked until the stack waiter is unlinked and marked complete.
  U32 flags=I386IrqSave;
  CI386AtaWaiter *node,*previous=0;
  Bool ok=FALSE;
  if(!channel || channel->signature!=I386_ATA_CHANNEL_MAGIC || !channel->scheduler ||
      !channel->scheduler->root || !task || task->owner!=channel->scheduler ||
      task->finished || channel->owner==task) goto cancel_done;
  node=channel->head;
  while(node && node->task!=task) { previous=node; node=node->next; }
  if(!node || !node->queued) goto cancel_done;
  //Wake cannot switch tasks; validate it before modifying the queue.
  if(task->blocked && !I386SchedWake(channel->scheduler,task)) goto cancel_done;
  if(previous) previous->next=node->next;
  else channel->head=node->next;
  if(channel->tail==node) channel->tail=previous;
  node->next=0; node->queued=FALSE;
  if(task->wait && task->wait->kind==I386_WAIT_ATA && task->wait->object==channel)
    task->wait->cancelled=TRUE;
  ok=TRUE;
cancel_done:
  I386IrqRestore(flags); return ok;
}
