Bool jr_worker_started;
U0 JRWorker(U8 *data)
{
  jr_worker_started=TRUE;
  while(TRUE){JobsHndlr(GetRFlags);Yield;}
}
I64 JRWorkerOne(CTask *task)
{
  CJob *job;
  I64 result=0,mask=0;
  job=TaskExe(task,Fs,"6*7;",1<<JOBf_WAKE_MASTER);
  if(!job)return 0;
  if(job->job_code==JOBT_EXE_STR&&job->master_task==Fs&&job->ctrl==&task->srv_ctrl)mask|=1;
  if(Bt(&job->flags,JOBf_DISPATCHED))mask|=2;
  if(Bt(&job->flags,JOBf_DONE))mask|=4;
  if(!IsSuspended(Fs))mask|=8;
  if(JobResScan(job,&result)&&result==42)mask|=16;
  if(Fs->srv_ctrl.next_done==&Fs->srv_ctrl.next_done&&task->srv_ctrl.next_waiting==&task->srv_ctrl.next_waiting)mask|=32;
  return mask;
}
I64 JRContract()
{
  CTask *task;
  I64 i,mask=63;
  jr_worker_started=FALSE;
  task=Spawn(&JRWorker,NULL,"Job worker",-1,Fs);
  while(!jr_worker_started)Yield;
  for(i=0;i<10;i++)mask&=JRWorkerOne(task);
  Kill(task);
  return mask;
}
