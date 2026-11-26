I64 mp_cnt=1;

CJob *JobQue(I64 (*fp_addr)(U8 *data),U8 *data=NULL,
    I64 target_cpu=1,I64 flags=1<<JOBf_FREE_ON_COMPLETE,
    I64 job_code=JOBT_CALL,U8 *aux_str=NULL,I64 aux1=0,I64 aux2=0)
{
  CTask *seth=Gs->seth_task;
  CJob *job;
  CJobCtrl *ctrl=&seth->srv_ctrl;
  I64 saved;
  if(target_cpu!=0)throw('MultCore',TRUE);
  job=ACAlloc(sizeof(CJob));
  if(aux_str)job->aux_str=AStrNew(aux_str);
  job->job_code=job_code;
  job->addr=fp_addr;
  job->fun_arg=data;
  job->flags=flags;
  job->aux1=aux1;
  job->aux2=aux2;
  job->ctrl=ctrl;
  saved=GetRFlags;
  SetRFlags(saved&~512);
  while(LBts(&ctrl->flags,JOBCf_LOCKED)) {}
  LBtr(&seth->task_flags,TASKf_AWAITING_MSG);
  LBtr(&seth->task_flags,TASKf_IDLE);
  QueIns(job,ctrl->last_waiting);
  LBtr(&ctrl->flags,JOBCf_LOCKED);
  SetRFlags(saved);
  return job;
}

I64 JobResGet(CJob *job=NULL)
{
  I64 res;
  while(!JobResScan(job,&res))Yield;
  return res;
}
