Bool jn_inner_ok;
U0 JNOuter()
{
  CJob *job=TaskExe(Fs,Fs,"6*7;",0);
  I64 value=0;
  JobsHndlr(GetRFlags);
  jn_inner_ok=job&&Bt(&job->flags,JOBf_DONE)&&JobResScan(job,&value)&&value==42;
}
I64 JNOne()
{
  CJob *job;
  I64 value=123,mask=0;
  jn_inner_ok=FALSE;
  job=TaskExe(Fs,Fs,"JNOuter;",0);
  if(!job)return 0;
  if(!JobResScan(job,&value)&&!value)mask|=1;
  JobsHndlr(GetRFlags);
  if(jn_inner_ok)mask|=2;
  if(Bt(&job->flags,JOBf_DISPATCHED))mask|=4;
  if(Bt(&job->flags,JOBf_DONE))mask|=8;
  if(JobResScan(job,&value))mask|=16;
  if(Fs->srv_ctrl.next_waiting==&Fs->srv_ctrl.next_waiting&&Fs->srv_ctrl.next_done==&Fs->srv_ctrl.next_done)mask|=32;
  return mask;
}
I64 JRContract()
{
  I64 i,mask=63;
  for(i=0;i<10;i++)mask&=JNOne;
  return mask;
}
