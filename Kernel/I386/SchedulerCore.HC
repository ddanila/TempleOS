#include "/Kernel/I386/Scheduler.HH"
#include "/Kernel/I386/Cpu.HH"
//Single CPU. Only Wake may be called from a maskable IRQ; never use from NMI.
//Records start zeroed and stay live until detached. No concurrent scheduler reset.
I64 I386TaskHeapHooks(CI386Task *task)
{//Readable task required. Validate all public pointers and private hooks together.
  return (task->code_heap!=0) | (task->data_heap!=0)<<1 | (task->heap_state!=0)<<2 |
    (task->heap_clone!=0)<<3 | (task->heap_destroy!=0)<<4;
}
public Bool I386SchedInit(CI386Scheduler *s,CI386Task *root,
  U0 (*swap)(CI386Context *old,CI386Context *next))
{
  I64 i;
  if (!s || !root || !swap || s->root || root->owner || root->next_task || root->last_task || root->except_top || root->io_locks ||
      root->file_state || root->file_clone || root->file_destroy || root->lifetime_refs ||
      root->hash_table || root->symbol_state || root->symbol_clone || root->symbol_destroy ||
      root->next_cc || root->last_cc || root->compiler_cleanup || root->active_controls ||
      root->compiler_cleanup_failed || root->compiler_busy || root->wait ||
      I386TaskHeapHooks(root)) return FALSE;
  root->addr=root; root->context.esp=0; root->next=root; root->last=root;
  root->next_task=root; root->last_task=root;
  root->task_signature=TASK_SIGNATURE_VAL;
  root->owner=s; root->finished=0; root->blocked=0;
  root->join_head=0; root->join_next=0; root->join_target=0;
  root->memory=0;
  root->cleanup=0; root->finishing=0;
  root->next_cc=root->last_cc=&root->next_cc;
  root->messages=0;
  root->except_ch=0; root->catch_except=0; root->except_rbp=0;
  for(i=0;i<I386_EXCEPT_CALLERS;i++) root->except_callers[i]=0;
  root->stk=0;
  s->root=root; s->current=root; s->swap=swap; s->bind=0;
  s->focus=0; s->jiffies=0;
  return TRUE;
}
public Bool I386SchedAdd(CI386Scheduler *s,CI386Task *task)
{//Append a freshly prepared context before root; caller owns its stack lifetime.
  U32 flags=I386IrqSave;
  I64 i;
  if (!s || !s->root || !task || task->owner || task->next_task || task->last_task || task->except_top || task->io_locks || task->lifetime_refs || !task->context.esp ||
      task->next_cc || task->last_cc || task->compiler_cleanup || task->active_controls ||
      task->compiler_cleanup_failed || task->compiler_busy || task->wait ||
      (I386TaskHeapHooks(task) && I386TaskHeapHooks(task)!=31) ||
      ((task->hash_table || task->symbol_state || task->symbol_clone || task->symbol_destroy) &&
       (!task->hash_table || !task->symbol_state || !task->symbol_clone || !task->symbol_destroy)) ||
      ((task->file_state || task->file_clone || task->file_destroy) &&
       (!task->file_state || !task->file_clone || !task->file_destroy))) {
    I386IrqRestore(flags); return FALSE;
  }
  task->addr=task; task->owner=s; task->finished=0; task->blocked=0;
  task->task_signature=TASK_SIGNATURE_VAL;
  task->join_head=0; task->join_next=0; task->join_target=0;
  task->cleanup=0; task->finishing=0;
  task->next_cc=task->last_cc=&task->next_cc;
  task->messages=0;
  task->except_ch=0; task->catch_except=0; task->except_rbp=0;
  for(i=0;i<I386_EXCEPT_CALLERS;i++) task->except_callers[i]=0;
  task->next=s->root; task->last=s->root->last;
  task->last->next=task; s->root->last=task;
  //Public ring contains every attached live task, including blocked workers.
  //Only the private next/last ring is restricted to runnable tasks.
  task->next_task=s->root; task->last_task=s->root->last_task;
  task->last_task->next_task=task; s->root->last_task=task;
  I386IrqRestore(flags);
  return TRUE;
}
Bool I386SchedReady(CI386Task *task)
{
  I64 now=0;
  if(task->owner->jiffies) now=*task->owner->jiffies;
  return !task->blocked && !task->finished &&
    !(task->task_flags & (1<<TASKf_SUSPENDED|1<<TASKf_AWAITING_MSG)) &&
    task->wake_jiffy<=now;
}
public Bool I386SchedSetClock(CI386Scheduler *s,I64 *jiffies)
{//Bind once, before any worker attachment or context switch.
  U32 flags=I386IrqSave;
  if(!s || !s->root || !jiffies || s->jiffies || s->current!=s->root ||
      s->root->next_task!=s->root || s->root->context.esp) {
    I386IrqRestore(flags); return FALSE;
  }
  s->jiffies=jiffies;
  I386IrqRestore(flags); return TRUE;
}
CI386Task *I386SchedNext(CI386Task *task)
{//IF clear. An IRQ may make a task eligible; never return an ineligible task.
  CI386Task *first=task;
  while(TRUE) {
    do {
      task=task->next_task;
      if(I386SchedReady(task)) return task;
    } while(task!=first);
    //STI's interrupt shadow closes the check/halt race. Resume with IF clear.
    asm {
      STI
      HLT
      CLI
    }
  }
}
public Bool I386SchedYield(CI386Scheduler *s)
{
  U32 flags=I386IrqSave;
  CI386Task *old,*next;
  if (!s || !s->current) { I386IrqRestore(flags); return FALSE; }
  old=s->current; next=I386SchedNext(old);
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
  if (!s || !s->current || s->current==s->root || s->current->finishing || s->current->io_locks || s->current->wait) {
    I386IrqRestore(flags); return FALSE;
  }
  old=s->current;
  old->finishing=1;
  if (old->cleanup) {
    I386IrqRestore(flags);
    (*old->cleanup)(old);
    flags=I386IrqSave;
  }
  if(old->compiler_cleanup) {
    I386IrqRestore(flags);
    old->compiler_cleanup_failed=!(*old->compiler_cleanup)(old);
    flags=I386IrqSave;
  }
  if(old->active_controls) old->compiler_cleanup_failed=1;
  old->last->next=old->next; old->next->last=old->last;
  old->next=0; old->last=0; old->finished=1;
  next=old->last_task;
  old->last_task->next_task=old->next_task;
  old->next_task->last_task=old->last_task;
  old->next_task=0; old->last_task=0;
  for (waiter=old->join_head;waiter;waiter=waiter->join_next)
    I386SchedWake(s,waiter);
  next=I386SchedNext(next);
  s->current=next;
  if (s->bind) (*s->bind)(next);
  (*s->swap)(&old->context,&next->context);
  //A finished context must never be selected again.
  while (1) {}
}
public Bool I386SchedReap(CI386Scheduler *s,CI386Task *task)
{//Detach a finished task from another stack before its owner frees that stack.
  U32 flags=I386IrqSave;
  I64 i;
  if (!s || !task || task->owner!=s || !task->finished || task==s->current || task->next_task || task->last_task ||
      task->join_head || task->join_target || task->messages || task->except_top || task->io_locks || task->lifetime_refs || task->active_controls || task->compiler_cleanup ||
      task->compiler_cleanup_failed || task->compiler_busy || task->wait ||
      task->next_cc!=&task->next_cc || task->last_cc!=&task->next_cc || s->focus==task) {
    I386IrqRestore(flags); return FALSE;
  }
  if(task->file_state || task->file_clone || task->file_destroy) {
    if(!task->file_state || !task->file_clone || !task->file_destroy ||
        !(*task->file_destroy)(task) || task->file_state || task->file_clone || task->file_destroy) {
      I386IrqRestore(flags); return FALSE;
    }
  }
  if(task->hash_table || task->symbol_state || task->symbol_clone || task->symbol_destroy) {
    if(!task->hash_table || !task->symbol_state || !task->symbol_clone || !task->symbol_destroy ||
        !(*task->symbol_destroy)(task) || task->hash_table || task->symbol_state || task->symbol_clone || task->symbol_destroy) {
      I386IrqRestore(flags); return FALSE;
    }
  }
  //Public heaps outlive compiler controls and file/symbol destruction.
  if(I386TaskHeapHooks(task)) {
    if(I386TaskHeapHooks(task)!=31 || !(*task->heap_destroy)(task) || I386TaskHeapHooks(task)) {
      I386IrqRestore(flags); return FALSE;
    }
  }
  task->except_ch=0; task->catch_except=0; task->except_rbp=0;
  for(i=0;i<I386_EXCEPT_CALLERS;i++) task->except_callers[i]=0;
  task->next_cc=task->last_cc=0;
  task->addr=0; task->context.esp=0; task->owner=0; task->finished=0; task->blocked=0;
  task->task_signature=0; task->gs=0;
  task->memory=0;
  task->stk=0;
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
  old=s->current;
  old->last->next=old->next; old->next->last=old->last;
  old->next=0; old->last=0; old->blocked=1;
  next=I386SchedNext(old);
  if(next!=old) {
    s->current=next;
    if (s->bind) (*s->bind)(next);
    (*s->swap)(&old->context,&next->context);
  }
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
{//Root only. Public flags may suspend tasks that remain privately runnable.
  U32 flags=I386IrqSave;
  CI386Task *task;
  if (!s || !s->root || s->current!=s->root || !idle) {
    I386IrqRestore(flags); return FALSE;
  }
  for(task=s->root->next_task;task!=s->root;task=task->next_task)
    if(I386SchedReady(task)) { I386IrqRestore(flags); return FALSE; }
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
