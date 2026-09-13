#include "/Kernel/I386/Scheduler.HH"
#include "/Kernel/I386/Cpu.HH"
//Single CPU. Only Wake may be called from a maskable IRQ; never use from NMI.
//Records start zeroed and stay live until detached. No concurrent scheduler reset.
public Bool I386SchedInit(CI386Scheduler *s,CI386Task *root,
  U0 (*swap)(CI386Context *old,CI386Context *next))
{
  if (!s || !root || !swap || s->root || root->owner) return FALSE;
  root->addr=root; root->context.esp=0; root->next=root; root->last=root;
  root->owner=s; root->finished=0; root->blocked=0;
  root->join_head=0; root->join_next=0; root->join_target=0;
  root->memory=0;
  root->cleanup=0; root->finishing=0;
  root->messages=0;
  s->root=root; s->current=root; s->swap=swap; s->bind=0;
  s->focus=0;
  return TRUE;
}
public Bool I386SchedAdd(CI386Scheduler *s,CI386Task *task)
{//Append a freshly prepared context before root; caller owns its stack lifetime.
  U32 flags=I386IrqSave;
  if (!s || !s->root || !task || task->owner || !task->context.esp) {
    I386IrqRestore(flags); return FALSE;
  }
  task->addr=task; task->owner=s; task->finished=0; task->blocked=0;
  task->join_head=0; task->join_next=0; task->join_target=0;
  task->cleanup=0; task->finishing=0;
  task->messages=0;
  task->next=s->root; task->last=s->root->last;
  task->last->next=task; s->root->last=task;
  I386IrqRestore(flags);
  return TRUE;
}
public Bool I386SchedYield(CI386Scheduler *s)
{
  U32 flags=I386IrqSave;
  CI386Task *old,*next;
  if (!s || !s->current) { I386IrqRestore(flags); return FALSE; }
  old=s->current; next=old->next;
  if (next!=old) {
    s->current=next;
    if (s->bind) (*s->bind)(next);
    (*s->swap)(&old->context,&next->context);
  }
  I386IrqRestore(flags);
  return TRUE;
}
public Bool I386SchedFinish(CI386Scheduler *s)
{//Root cannot finish. Successful completion never returns to this task.
  U32 flags=I386IrqSave;
  CI386Task *old,*next,*waiter;
  if (!s || !s->current || s->current==s->root || s->current->finishing) {
    I386IrqRestore(flags); return FALSE;
  }
  old=s->current;
  old->finishing=1;
  if (old->cleanup) {
    I386IrqRestore(flags);
    (*old->cleanup)(old);
    flags=I386IrqSave;
  }
  next=old->next;
  old->last->next=next; next->last=old->last;
  old->next=0; old->last=0; old->finished=1;
  for (waiter=old->join_head;waiter;waiter=waiter->join_next)
    I386SchedWake(s,waiter);
  s->current=next;
  if (s->bind) (*s->bind)(next);
  (*s->swap)(&old->context,&next->context);
  //A finished context must never be selected again.
  while (1) {}
}
public Bool I386SchedReap(CI386Scheduler *s,CI386Task *task)
{//Detach a finished task from another stack before its owner frees that stack.
  U32 flags=I386IrqSave;
  if (!s || !task || task->owner!=s || !task->finished || task==s->current ||
      task->join_head || task->join_target || task->messages || s->focus==task) {
    I386IrqRestore(flags); return FALSE;
  }
  task->addr=0; task->context.esp=0; task->owner=0; task->finished=0; task->blocked=0;
  task->memory=0;
  task->cleanup=0; task->finishing=0;
  I386IrqRestore(flags);
  return TRUE;
}
public Bool I386SchedBlock(CI386Scheduler *s)
{//Caller must mask IRQs before checking an IRQ-owned wait condition.
  U32 flags=I386IrqSave;
  CI386Task *old,*next;
  if (!s || !s->current || s->current==s->root) {
    I386IrqRestore(flags); return FALSE;
  }
  old=s->current; next=old->next;
  old->last->next=next; next->last=old->last;
  old->next=0; old->last=0; old->blocked=1;
  s->current=next;
  if (s->bind) (*s->bind)(next);
  (*s->swap)(&old->context,&next->context);
  I386IrqRestore(flags);
  return TRUE;
}
public Bool I386SchedWake(CI386Scheduler *s,CI386Task *task)
{//IRQ-safe queue insertion only; does not switch or preempt the running task.
  U32 flags=I386IrqSave;
  if (!s || !s->root || !task || task->owner!=s || !task->blocked || task->finished) {
    I386IrqRestore(flags); return FALSE;
  }
  task->blocked=0;
  task->next=s->root; task->last=s->root->last;
  task->last->next=task; s->root->last=task;
  I386IrqRestore(flags);
  return TRUE;
}
public Bool I386SchedIdle(CI386Scheduler *s,U0 (*idle)())
{//Root only. Keep IF clear from the queue check to the atomic enable/halt helper.
  U32 flags=I386IrqSave;
  if (!s || !s->root || s->current!=s->root || !idle || s->root->next!=s->root) {
    I386IrqRestore(flags); return FALSE;
  }
  (*idle)();
  I386IrqRestore(flags);
  return TRUE;
}
public Bool I386SchedSetBind(CI386Scheduler *s,U0 (*bind)(CI386Task *task))
{//Install once on a fresh root before any switch or task attachment.
  U32 flags=I386IrqSave;
  if (!s || !s->root || !bind || s->bind || s->current!=s->root ||
      s->root->next!=s->root || s->root->context.esp) {
    I386IrqRestore(flags); return FALSE;
  }
  s->bind=bind;
  (*bind)(s->root);
  I386IrqRestore(flags);
  return TRUE;
}
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
  while (!target->finished) I386SchedBlock(s);
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
public Bool I386SchedSetCleanup(CI386Scheduler *s,U0 (*cleanup)(CI386Task *task))
{//Current worker only. A null callback clears a previously installed hook.
  U32 flags=I386IrqSave;
  if (!s || !s->current || s->current==s->root || s->current->finishing) {
    I386IrqRestore(flags); return FALSE;
  }
  s->current->cleanup=cleanup;
  I386IrqRestore(flags);
  return TRUE;
}
