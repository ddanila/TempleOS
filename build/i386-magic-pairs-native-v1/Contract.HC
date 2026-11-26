CTask *job_observed;
I64 ProbeWorker(U8 *data)
{
  job_observed=Fs;
  return *data;
}
U0 ProbeJobs()
{
  U8 value=67;
  CJob *request=JobQue(&ProbeWorker,&value,0,0);
  Bool early=job_observed!=NULL;
  I64 result=JobResGet(request);
  Bool right_task=job_observed==Gs->seth_task && job_observed!=Fs;
  U8 *line=MStrPrint("CALL early=%d result=%d correct_task=%d\n",early,result,right_task);
  U8 *cursor=line;
  while(*cursor)OutU8(0xE9,*cursor++);
  Free(line);
  if(result!=67 || !right_task)throw('JobTest',TRUE);
}
ProbeJobs;
U0 ProbeJobPublic()
{
  Bool rejected=FALSE;
  try {
    JobQue(&ProbeWorker,NULL,mp_cnt,0);
  } catch {
    if(Fs->except_ch=='MultCore') {
      rejected=TRUE;
      Fs->catch_except=TRUE;
    }
  }
  if(mp_cnt!=1 || !rejected)throw('JobTest',TRUE);
  if(!TaskExe(adam_task,Fs,"6*7;",0) || JobResGet()!=42)
    throw('JobTest',TRUE);
}
ProbeJobPublic;
