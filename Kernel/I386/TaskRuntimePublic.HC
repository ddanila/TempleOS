//Public single-CPU task policy. Include after the retained lifecycle helpers.
class CMemoryTaskRecord {
  CMemoryTaskRecord *next;
  CI386OwnedTask *owned;
  U0 (*entry)(U8 *data);
  U0 (*end_callback)();
  Bool child_linked,exiting;
};
CMemoryTaskRecord *memory_tasks;
I64 memory_task_number=1;
CTask *MemoryChildHead(CTask *task)
{
  return (&task->next_child_task)(U8 *)-offset(CTask.next_sibling_task);
}
U0 MemoryTaskRootInit(CI386Task *root)
{
  root->next_child_task=root->last_child_task=MemoryChildHead(root);
  root->next_sibling_task=root->last_sibling_task=root;
  root->task_num=memory_task_number;
  if(!root->gs->seth_task) root->gs->seth_task=root;
}
Bool MemoryTaskEnsure(CI386Task *task)
{//Private boot workers enter the public task model on their first managed yield.
  CTask *head;
  if(!task || !memory_root || task->owner!=memory_root->owner ||
      task->addr!=task || task->task_signature!=TASK_SIGNATURE_VAL ||
      task->finished) return FALSE;
  if(!task->next_child_task && !task->last_child_task) {
    head=MemoryChildHead(task);
    task->next_child_task=head; task->last_child_task=head;
  } else if(!task->next_child_task || !task->last_child_task) return FALSE;
  if(!task->next_sibling_task && !task->last_sibling_task) {
    task->next_sibling_task=task; task->last_sibling_task=task;
  }
  if(!task->task_num) task->task_num=++memory_task_number;
  if(task!=memory_root && !task->parent_task) task->parent_task=memory_root;
  return TRUE;
}
CMemoryTaskRecord *MemoryTaskFind(CTask *task)
{
  CMemoryTaskRecord *record;
  for(record=memory_tasks;record;record=record->next)
    if(&record->owned->task==task) return record;
  return 0;
}
U0 MemoryTaskEntry(U8 *data)
{//A canceled queued task must not enter user code for the first time.
  CMemoryTaskRecord *record=MemoryTaskFind(I386TaskSelf);
  if(!record) KernelStop;
  if(!(I386TaskSelf->task_flags&(1<<TASKf_KILL_TASK))) (*record->entry)(data);
  Exit;
}
Bool MemoryTaskActivate(CTask *public_task,CTask *pred)
{
  CMemoryTaskRecord *record=MemoryTaskFind(public_task);
  CI386Task *task=public_task,*before=pred;
  if(!record || !before || before==task || before->owner!=memory_root->owner ||
      before->finished || !before->next_task || !before->last_task ||
      !TaskRuntimeSchedActivate(memory_root->owner,task)) return FALSE;
  //The private ring stays attached; public dispatch inserts before pred.
  task->last_task->next_task=task->next_task;
  task->next_task->last_task=task->last_task;
  task->next_task=pred; task->last_task=pred->last_task;
  task->last_task->next_task=task; pred->last_task=task;
  return TRUE;
}
U0 TaskQueIns(CTask *task,CTask *pred=0)
{
  U32 irq=I386IrqSave;
  Bool result;
  if(!pred) pred=I386TaskSelf;
  result=MemoryTaskActivate(task,pred);
  I386IrqRestore(irq);
  if(!result) throw('Task',TRUE);
}
CTask *Spawn(U0 (*entry)(U8 *data),U8 *data=0,U8 *name=0,
  I64 target_cpu=-1,CTask *parent=0,I64 stack_size=0,I64 flags=256)
{
  U32 irq=I386IrqSave;
  CMemoryTaskRecord *record;
  CI386OwnedTask *owned;
  CI386Task *task;
  CTask *head,*last;
  I64 i;
  if(!parent && memory_root) parent=memory_root->gs->seth_task;
  if(!memory_root || !entry || !parent || (target_cpu!=-1 && target_cpu!=0) ||
      !MemoryTaskEnsure(parent)) {
    I386IrqRestore(irq); throw('Task',TRUE); return 0;
  }
  record=MemoryTaskFind(parent);
  if(record && record->exiting) {
    I386IrqRestore(irq); throw('Task',TRUE); return 0;
  }
  if(!stack_size) stack_size=MEM_DFT_STK;
  record=I386HeapAlloc(memory_pool.heap,sizeof(CMemoryTaskRecord),TRUE);
  if(!record) { I386IrqRestore(irq); throw('OutMem',TRUE); return 0; }
  owned=TaskRuntimeTaskCreateFrom(memory_root->owner,memory_pool.heap,parent,
      stack_size,&MemoryTaskEntry,(data+0)(U64),0x18,0x20);
  if(!owned) {
    I386HeapFree(memory_pool.heap,record);
    I386IrqRestore(irq); throw('OutMem',TRUE); return 0;
  }
  task=&owned->task;
  //Exception records use kernel-lifetime scratch storage, owned by this task's
  //except_top chain. Public code/data allocations still use its cloned heaps.
  task->memory=memory_pool.heap;
  task->parent_task=parent; task->gs=parent->gs;
  task->task_num=++memory_task_number;
  task->next_child_task=task->last_child_task=MemoryChildHead(task);
  task->next_sibling_task=task->last_sibling_task=task;
  task->rflags=0x202; task->context.esp(U32 *)[12]=0x202;
  task->context.esp(U32 *)[18]=&Exit;
  task->rip=(entry+0)(U64);
  if(!name) name="Unnamed Task";
  for(i=0;i<TASK_NAME_LEN-1 && name[i];i++) task->task_name[i]=name[i];
  task->task_name[i]=0; MemoryStrCopy(task->task_title,task->task_name);
  record->owned=owned; record->entry=entry;
  record->next=memory_tasks; memory_tasks=record;
  if(flags&256) {
    head=parent->last_child_task; last=head->last_sibling_task;
    task->next_sibling_task=head; task->last_sibling_task=last;
    last->next_sibling_task=task; head->last_sibling_task=task;
    record->child_linked=TRUE;
    if(!MemoryTaskActivate(task,I386TaskSelf)) KernelStop;
  }
  I386IrqRestore(irq); return task;
}
U0 Exit()
{
  CI386Task *task=I386TaskSelf;
  CMemoryTaskRecord *record;
  CTask *head,*child;
  U32 irq=I386IrqSave;
  if(!task || task==memory_root || !(record=MemoryTaskFind(task))) {
    I386IrqRestore(irq); throw('Task',TRUE); return;
  }
  //A callback may throw to the task's active try and resume normal execution.
  //Keep its exception chain and child creation available until it actually exits.
  if(task->task_end_cb) {
    record->end_callback=task->task_end_cb;
    task->task_end_cb=0;
    task->wake_jiffy=0;
    task->task_flags&=~(1<<TASKf_KILL_TASK|1<<TASKf_SUSPENDED|1<<TASKf_AWAITING_MSG);
    I386IrqRestore(irq);
    (*record->end_callback)();
    Exit;
    return;
  }
  record->exiting=TRUE;
  head=MemoryChildHead(task);
  //A descendant's callback can clear KILL and recover to its active catch.
  //Like TaskEnd, renew termination requests until all queued children retire.
  while(task->next_child_task!=head) {
    for(child=task->next_child_task;child!=head;child=child->next_sibling_task) {
      child->task_flags|=1<<TASKf_KILL_TASK;
      child->task_flags&=~(1<<TASKf_SUSPENDED|1<<TASKf_AWAITING_MSG|1<<TASKf_IDLE);
      child->wake_jiffy=0;
    }
    I386IrqRestore(irq);
    Yield;
    irq=I386IrqSave;
  }
  I386IrqRestore(irq);
  //Exit need not return through the lexical untry epilogues on this stack.
  while(task->except_top) SysUntry;
  if(!TaskRuntimeSchedFinish(task->owner)) throw('Task',TRUE);
}
U0 MemoryTaskCheckExit()
{
  CI386Task *task=I386TaskSelf;
  CMemoryTaskRecord *record=MemoryTaskFind(task);
  if(record && !record->exiting && !task->finishing && !task->io_locks &&
      !task->wait && task->task_flags&(1<<TASKf_KILL_TASK)) Exit;
}
U0 MemoryTaskReap()
{//Release completed owned tasks from another live stack; never the current stack.
  U32 irq=I386IrqSave;
  CMemoryTaskRecord *record,*last,*next;
  CI386Task *task;
  CTask *sibling_next,*sibling_last;
  Bool progress;
  if(!memory_root || I386TaskSelf->owner!=memory_root->owner ||
      I386TaskSelf->owner->current!=I386TaskSelf) { I386IrqRestore(irq); return; }
  do {
    progress=FALSE; last=0; record=memory_tasks;
    while(record) {
      next=record->next; task=&record->owned->task;
      if(task!=I386TaskSelf && task->finished && !task->lifetime_refs) {
        if(record->child_linked) {
          sibling_next=task->next_sibling_task; sibling_last=task->last_sibling_task;
          sibling_last->next_sibling_task=sibling_next;
          sibling_next->last_sibling_task=sibling_last;
        }
        if(TaskRuntimeTaskDestroy(record->owned)) {
          if(last) last->next=next; else memory_tasks=next;
          if(!I386HeapFree(memory_pool.heap,record)) KernelStop;
          progress=TRUE; goto memory_reap_advance;
        }
        if(record->child_linked) {
          sibling_last->next_sibling_task=task;
          sibling_next->last_sibling_task=task;
        }
      }
      last=record;
memory_reap_advance:
      record=next;
    }
  } while(progress);
  I386IrqRestore(irq);
}
Bool MemoryManagedYield(CI386Scheduler *scheduler)
{
  Bool result;
  U32 irq=I386IrqSave;
  if(!memory_root || scheduler!=memory_root->owner ||
      !MemoryTaskEnsure(I386TaskSelf)) { I386IrqRestore(irq); return FALSE; }
  I386IrqRestore(irq);
  MemoryTaskCheckExit;
  MemoryTaskReap;
  result=MemoryCoreYield(scheduler);
  MemoryTaskCheckExit;
  MemoryTaskReap;
  return result;
}
