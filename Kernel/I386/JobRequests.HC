U0 NativeTaskRstAwaitingMsg(CTask *task)
{//Original popup chain also stops waiting when its parent's job arrives.
  do {
    if(!TaskValidate(task)) break;
    LBtr(&task->task_flags,TASKf_AWAITING_MSG);
  } while(task=task->popup_task);
}
CJob *NativeTaskExeOwned(CTask *srv,CTask *master,U8 *data,I64 flags,CJob **owned)
{//Copy executable source into root-owned request storage, as in original TaskExe.
  CJob *job=NULL;
  CTask *root=I386TaskSelf->owner->root;
  Bool queued=FALSE;
  U32 irq;
  if(!data || !TaskValidate(srv) || master && !TaskValidate(master) ||
      srv->popup_task && !Bt(&srv->task_flags,TASKf_FILTER_INPUT)) return NULL;
  irq=I386IrqSave;
  try {
    if(!TaskValidate(srv) || srv(CI386Task *)->finishing) {
      I386IrqRestore(irq); return NULL;
    }
    job=CAlloc(sizeof(CJob),root);
    job->aux_str=StrNew(data,root);
    job->master_task=master; job->job_code=JOBT_EXE_STR;
    job->flags=flags; job->ctrl=&srv->srv_ctrl;
    while(LBts(&srv->srv_ctrl.flags,JOBCf_LOCKED)) {}
    LBtr(&srv->task_flags,TASKf_IDLE);
    NativeTaskRstAwaitingMsg(srv);
    QueIns(job,srv->srv_ctrl.last_waiting);
    queued=TRUE;
    if(owned)*owned=job;
    LBtr(&srv->srv_ctrl.flags,JOBCf_LOCKED);
    I386SchedWake(srv(CI386Task *)->owner,srv);
    if(Bt(&flags,JOBf_WAKE_MASTER)) {
      (*native_user_providers.suspend)(master,TRUE);
      (*native_input_yield)();
    }
  } catch {
    if(!queued && job) JobDel(job);
    I386IrqRestore(irq);
  }
  I386IrqRestore(irq); return job;
}

CJob *NativeTaskExe(CTask *srv,CTask *master,U8 *data,I64 flags)
{ return NativeTaskExeOwned(srv,master,data,flags,NULL); }

I64 native_mp_cnt=1;

CJob *NativeJobQue(I64 (*fp_addr)(U8 *data),U8 *data=NULL,
  I64 target_cpu=1,I64 flags=1<<JOBf_FREE_ON_COMPLETE,
  I64 job_code=JOBT_CALL,U8 *aux_str=NULL,I64 aux1=0,I64 aux2=0)
{//CPU zero's Seth queue is served by the scheduler root.
  CI386Task *seth=I386TaskSelf->gs->seth_task;
  CJobCtrl *ctrl;
  CJob *job=NULL;
  U32 irq;
  if(target_cpu!=0)throw('MultCore');
  ctrl=&seth->srv_ctrl;
  irq=I386IrqSave;
  try {
    job=CAlloc(sizeof(CJob),seth);
    if(aux_str)job->aux_str=StrNew(aux_str,seth);
  } catch {
    if(job)JobDel(job);
    I386IrqRestore(irq);
  }
  job->job_code=job_code;
  job->addr=fp_addr;
  job->fun_arg=data;
  job->flags=flags;
  job->aux1=aux1;
  job->aux2=aux2;
  job->ctrl=ctrl;
  while(LBts(&ctrl->flags,JOBCf_LOCKED)) {}
  LBtr(&seth->task_flags,TASKf_IDLE);
  NativeTaskRstAwaitingMsg(seth);
  QueIns(job,ctrl->last_waiting);
  LBtr(&ctrl->flags,JOBCf_LOCKED);
  I386SchedWake(seth->owner,seth);
  I386IrqRestore(irq);
  return job;
}

I64 NativeJobResGet(CJob *job=NULL)
{
  CI386Task *task=I386TaskSelf;
  CJob *head=&task->srv_ctrl.next_done;
  I64 res;
  if(job) {
    while(!Bt(&job->flags,JOBf_DONE)) {
      LBts(&task->task_flags,TASKf_IDLE);
      (*native_input_yield)();
    }
  } else {
    while(head->next==head) {
      LBts(&task->task_flags,TASKf_IDLE);
      (*native_input_yield)();
    }
  }
  LBtr(&task->task_flags,TASKf_IDLE);
  JobResScan(job,&res);
  return res;
}
