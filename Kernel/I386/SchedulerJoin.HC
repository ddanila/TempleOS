#include "/Kernel/I386/Scheduler.HH"
#include "/Kernel/I386/Cpu.HH"
public Bool I386SchedJoin(CI386Scheduler *s,CI386Task *target)
{//Task context only. Root may observe completion but cannot block.
  U32 flags=I386IrqSave;
  CI386Task *self,*node;
  if (!s || !s->current || !target || target->owner!=s || target==s->current || target==s->root) {
    I386IrqRestore(flags); return FALSE;
  }
  if (target->finished) { I386IrqRestore(flags); return TRUE; }
  self=s->current;
  if (self==s->root) { I386IrqRestore(flags); return FALSE; }
  //Reject cycles through existing join dependencies before registering a waiter.
  for (node=target;node;node=node->join_target) if (node==self) {
    I386IrqRestore(flags); return FALSE;
  }
  self->join_target=target; self->join_next=target->join_head; target->join_head=self;
  //A generic Wake can be spurious for a join; completion is the predicate.
  while (self->join_target && !target->finished) I386SchedBlock(s);
  //Cancellation releases the target pin. It may already have been reaped.
  if(!self->join_target) { I386IrqRestore(flags); return FALSE; }
  node=target->join_head;
  if (node==self) target->join_head=self->join_next;
  else {
    while (node->join_next!=self) node=node->join_next;
    node->join_next=self->join_next;
  }
  self->join_next=0; self->join_target=0;
  I386IrqRestore(flags);
  return TRUE;
}

public Bool I386SchedCancelJoin(CI386Scheduler *s,CI386Task *task)
{
  U32 flags=I386IrqSave;
  CI386Task *target,*node,*previous=0;
  Bool ok=FALSE;
  if(!s || !s->root || !task || task->owner!=s || task->finished ||
      !(target=task->join_target) || target->owner!=s || target->finished) goto cancel_done;
  node=target->join_head;
  while(node && node!=task) { previous=node; node=node->join_next; }
  if(!node) goto cancel_done;
  if(task->blocked && !I386SchedWake(s,task)) goto cancel_done;
  if(previous) previous->join_next=task->join_next;
  else target->join_head=task->join_next;
  task->join_target=0; task->join_next=0;
  ok=TRUE;
cancel_done:
  I386IrqRestore(flags); return ok;
}
