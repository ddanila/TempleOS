//Public job execution. Queue ownership stays in the retained memory provider.
class CMemoryJobHooks {
  I64 (*source)(U8 *text);
  CTask **focus;
};
U0 MemoryJobRemove(CJob *job)
{
  job->last->next=job->next;
  job->next->last=job->last;
}
U0 MemoryJobAppend(CJob *job,CJob *last)
{
  job->next=last->next; job->last=last;
  last->next->last=job; last->next=job;
}
I64 MemoryJobRunOne(U32 run_flags,CJobCtrl *ctrl)
{//Caller holds the queue lock with interrupts disabled.
  CJob *job=ctrl->next_waiting;
  CTask *master;
  CHashExport *symbol;
  CMemoryJobHooks hooks;
  I64 flags=job->flags,result=1;
  U32 old_flags=I386IrqSave;
  if(flags&(1<<JOBf_EXIT_ON_COMPLETE)) result=2;
  switch(job->job_code) {
    case JOBT_SPAWN_TASK:
      MemoryJobRemove(job); job->flags|=1<<JOBf_DISPATCHED;
      ctrl->flags&=~(1<<JOBCf_LOCKED);
      if(job->aux_str)
        job->spawned_task=Spawn(job->addr,job->fun_arg,job->aux_str,-1,
          job->aux1,job->aux2,job->flags);
      else job->spawned_task=Spawn(job->addr,job->fun_arg,"Unnamed",-1,
        job->aux1,job->aux2,job->flags);
      break;
    case JOBT_CALL:
    case JOBT_EXE_STR:
      MemoryJobRemove(job); job->flags|=1<<JOBf_DISPATCHED;
      ctrl->flags&=~(1<<JOBCf_LOCKED);
      I386IrqRestore(run_flags);
      I386TaskSelf->task_flags&=~(1<<TASKf_IDLE);
      try {
        if(job->job_code==JOBT_CALL) job->res=(*job->addr)(job->fun_arg);
        else {
          symbol=HashFind("_I386_JOB_SOURCE",I386TaskSelf->hash_table,HTT_EXPORT_SYS_SYM);
          if(!symbol) throw('JobSvc',TRUE);
          hooks.source=symbol->val;
          job->res=(*hooks.source)(job->aux_str);
        }
      } catch { I386TaskSelf->catch_except=TRUE; }
      I386IrqRestore(old_flags);
      break;
    default: return 0;
  }
  master=job->master_task;
  if(master) {
    if(!(flags&(1<<JOBf_FREE_ON_COMPLETE))) {
      I386IrqSave;
      while(master->srv_ctrl.flags&(1<<JOBCf_LOCKED)) {}
      master->srv_ctrl.flags|=1<<JOBCf_LOCKED;
      MemoryJobAppend(job,master->srv_ctrl.last_done);
      job->flags|=1<<JOBf_DONE;
      master->srv_ctrl.flags&=~(1<<JOBCf_LOCKED);
      I386IrqRestore(old_flags);
    }
    if(flags&(1<<JOBf_FOCUS_MASTER) && !(master->win_inhibit&1)) {
      symbol=HashFind("_SYS_FOCUS_TASK",I386TaskSelf->hash_table,HTT_EXPORT_SYS_SYM);
      if(!symbol) throw('JobSvc',TRUE);
      hooks.focus=symbol->val;
      *hooks.focus=master;
    }
    if(flags&(1<<JOBf_WAKE_MASTER)) MemorySuspend(master,FALSE);
  }
  if(flags&(1<<JOBf_FREE_ON_COMPLETE)) {
    MemoryFree(job->aux_str); MemoryFree(job);
  } else if(!master) {
    I386IrqSave;
    while(ctrl->flags&(1<<JOBCf_LOCKED)) Yield;
    ctrl->flags|=1<<JOBCf_LOCKED;
    MemoryJobAppend(job,ctrl->last_done);
    job->flags|=1<<JOBf_DONE;
    ctrl->flags&=~(1<<JOBCf_LOCKED);
    I386IrqRestore(old_flags);
  }
  return result;
}
I64 MemoryJobsHndlr(I64 run_flags,CTask *task=0)
{
  U32 old_flags=I386IrqSave;
  I64 count=0,result;
  CJobCtrl *ctrl;
  CJob *head;
  if(!task) task=I386TaskSelf;
  ctrl=&task->srv_ctrl; head=&ctrl->next_waiting;
  while(TRUE) {
    I386IrqSave;
    while(ctrl->flags&(1<<JOBCf_LOCKED)) {}
    ctrl->flags|=1<<JOBCf_LOCKED;
    if(ctrl->next_waiting==head) break;
    result=MemoryJobRunOne(run_flags,ctrl);
    if(!result) break;
    if(result==2) Exit;
    count++;
  }
  ctrl->flags&=~(1<<JOBCf_LOCKED);
  I386IrqRestore(old_flags);
  return count;
}
