#include "/Kernel/I386/Scheduler.HH"
#include "/Kernel/I386/Cpu.HH"
//Single CPU. Only Wake may be called from a maskable IRQ; never use from NMI.
//Records start zeroed and stay live until detached. No concurrent scheduler reset.
public Bool I386SchedInit(CI386Scheduler *s,CI386Task *root,
  U0 (*swap)(CI386Context *old,CI386Context *next))
{
  if (!s || !root || !swap || s->root || root->owner) return FALSE;
  root->context.esp=0; root->next=root; root->last=root;
  root->owner=s; root->finished=0; root->blocked=0;
  s->root=root; s->current=root; s->swap=swap;
  return TRUE;
}
public Bool I386SchedAdd(CI386Scheduler *s,CI386Task *task)
{//Append a freshly prepared context before root; caller owns its stack lifetime.
  U32 flags=I386IrqSave;
  if (!s || !s->root || !task || task->owner || !task->context.esp) {
    I386IrqRestore(flags); return FALSE;
  }
  task->owner=s; task->finished=0; task->blocked=0;
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
    (*s->swap)(&old->context,&next->context);
  }
  I386IrqRestore(flags);
  return TRUE;
}
public Bool I386SchedFinish(CI386Scheduler *s)
{//Root cannot finish. Successful completion never returns to this task.
  U32 flags=I386IrqSave;
  CI386Task *old,*next;
  if (!s || !s->current || s->current==s->root) {
    I386IrqRestore(flags); return FALSE;
  }
  old=s->current; next=old->next;
  old->last->next=next; next->last=old->last;
  old->next=0; old->last=0; old->finished=1;
  s->current=next;
  (*s->swap)(&old->context,&next->context);
  //A finished context must never be selected again.
  while (1) {}
}
public Bool I386SchedReap(CI386Scheduler *s,CI386Task *task)
{//Detach a finished task from another stack before its owner frees that stack.
  U32 flags=I386IrqSave;
  if (!s || !task || task->owner!=s || !task->finished || task==s->current) {
    I386IrqRestore(flags); return FALSE;
  }
  task->context.esp=0; task->owner=0; task->finished=0; task->blocked=0;
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
