I64 sr_hook_calls;
Bool sr_hook_inhibit;
U0 (*sr_original_hook)();
U0 SRHook()
{
  sr_hook_calls++;
  sr_hook_inhibit=Fs->win_inhibit==WIG_USER_TASK_DFT;
  (*sr_original_hook)();
}
I64 JRServantOne(CTask *task)
{
  CJob *job;
  I64 result=0,mask=0;
  if(task->win_inhibit==WIG_USER_TASK_DFT&&task->put_doc&&
      task->display_doc==task->put_doc&&task->border_doc&&task->cur_menu&&
      task->put_doc->max_entries==4096&&task->put_doc->desc=='Term'&&
      task->put_doc->right_click_link&&
      Bt(&task->display_flags,DISPLAYf_NOT_RAW))mask|=1;
  if(Bt(&task->task_flags,TASKf_IDLE)&&Bt(&task->task_flags,TASKf_AWAITING_MSG))mask|=2;
  StrCpy(task->task_title,"Temporary title");
  job=TaskExe(task,Fs,"6*7;",1<<JOBf_WAKE_MASTER);
  if(!job)return mask;
  if(Bt(&job->flags,JOBf_DISPATCHED)&&Bt(&job->flags,JOBf_DONE))mask|=4;
  if(!IsSuspended(Fs))mask|=8;
  if(JobResScan(job,&result)&&result==42)mask|=16;
  while(!Bt(&task->task_flags,TASKf_IDLE)||!Bt(&task->task_flags,TASKf_AWAITING_MSG))Yield;
  if(!StrCmp(task->task_title,task->task_name)&&
      Fs->srv_ctrl.next_done==&Fs->srv_ctrl.next_done&&
      task->srv_ctrl.next_waiting==&task->srv_ctrl.next_waiting)mask|=32;
  return mask;
}
I64 JRBaseContract()
{
  CTask *task=Spawn(&SrvCmdLine,NULL,"Servant contract",-1,Fs);
  I64 i,mask=63;
  while(!Bt(&task->task_flags,TASKf_IDLE)||!Bt(&task->task_flags,TASKf_AWAITING_MSG))Yield;
  for(i=0;i<10;i++)mask&=JRServantOne(task);
  Kill(task);
  return mask;
}

I64 JRContract()
{
  CHashFun *hook=HashFind("SrvStartUp",Fs->hash_table,HTT_FUN);
  I64 mask=0;
  if(!hook||!hook->exe_addr)return 0;
  sr_original_hook=hook->exe_addr;
  sr_hook_calls=0;sr_hook_inhibit=FALSE;
  hook->exe_addr=&SRHook;
  try {mask=JRBaseContract;}
  catch {hook->exe_addr=sr_original_hook;}
  hook->exe_addr=sr_original_hook;
  if(sr_hook_calls!=1||!sr_hook_inhibit)mask&=~1;
  return mask;
}
