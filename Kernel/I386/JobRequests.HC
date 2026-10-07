U0 NativeTaskRstAwaitingMsg(CTask *task)
{//Original popup chain also stops waiting when its parent's job arrives.
  do {
    if(!TaskValidate(task)) break;
    LBtr(&task->task_flags,TASKf_AWAITING_MSG);
  } while(task=task->popup_task);
}
CJob *NativeTaskExe(CTask *srv,CTask *master,U8 *data,I64 flags)
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
