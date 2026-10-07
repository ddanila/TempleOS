I64 JRExeOne()
{
  CJob *job;
  U8 *source=StrNew("6*7;");
  I64 result=0,mask=0;
  job=TaskExe(Fs,Fs,source,0);
  if(!job){Free(source);return 0;}
  if(job->job_code==JOBT_EXE_STR&&job->master_task==Fs&&job->ctrl==&Fs->srv_ctrl)mask|=1;
  source[0]='9';Free(source);
  if(StrCmp(job->aux_str,"6*7;")==0)mask|=2;
  if(!JobResScan(job,&result)&&!result)mask|=4;
  JobsHndlr(GetRFlags);
  if(Bt(&job->flags,JOBf_DONE))mask|=8;
  if(JobResScan(job,&result)&&result==42)mask|=16;
  if(Fs->srv_ctrl.next_waiting==&Fs->srv_ctrl.next_waiting&&Fs->srv_ctrl.next_done==&Fs->srv_ctrl.next_done)mask|=32;
  return mask;
}
I64 JRContract()
{
  I64 i,mask=63;
  for(i=0;i<10;i++)mask&=JRExeOne;
  return mask;
}
