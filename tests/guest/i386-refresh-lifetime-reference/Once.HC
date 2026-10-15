U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
CDoc *rf_waitdoc;
Bool rf_inside,rf_release,rf_started,rf_done;
I64 rf_leaked;
U0 (*rf_old_final)(CDC *dc);
U0 RFFinal(CDC *dc)
{if(Fs==sys_winmgr_task){rf_inside=TRUE;while(!rf_release)Yield;}}
U0 RFSyncWorker(U8 *data)
{Fs->put_doc=NULL;rf_started=TRUE;Refresh(0,FALSE);rf_done=TRUE;}
I64 RFActive()
{
  CTask *waiter;
  I64 i,m=0;
  rf_inside=rf_release=rf_started=rf_done=FALSE;
  rf_old_final=gr.fp_final_scrn_update;
  gr.fp_final_scrn_update=&RFFinal;
  while(!rf_inside)Sleep(1);
  if(Bt(&sys_semas[SEMA_REFRESH_IN_PROGRESS],0))m|=1;
  waiter=Spawn(&RFSyncWorker,NULL,"Refresh sync");
  while(!rf_started)Yield;
  for(i=0;i<128;i++)Yield;
  if(!rf_done&&Bt(&waiter->task_flags,TASKf_IDLE))m|=2;
  rf_release=TRUE;
  while(TaskValidate(waiter))Yield;
  if(rf_done)m|=4;
  if(!Bt(&sys_semas[SEMA_REFRESH_IN_PROGRESS],0))m|=8;
  gr.fp_final_scrn_update=rf_old_final;
  return m;
}
U0 RFAbort(){throw('RfStop',TRUE);}
U0 RFInterruptedWorker(U8 *data)
{
  Fs->put_doc=rf_waitdoc;Fs->task_end_cb=&RFAbort;
  try { Refresh(2,FALSE); }
  catch {
    if(Fs->except_ch=='RfStop') {
      Fs->catch_except=TRUE;
      rf_leaked=Bt(&Fs->task_flags,TASKf_IDLE)|
        Bt(&rf_waitdoc->flags,DOCf_DO_FULL_REFRESH)<<1;
    }
  }
  Fs->put_doc=NULL;Fs->task_end_cb=NULL;
}
I64 RFInterrupted()
{
  CTask *waiter;
  Suspend(sys_winmgr_task,TRUE);
  rf_waitdoc=DocNew("RefreshWait.DD");rf_leaked=-1;
  waiter=Spawn(&RFInterruptedWorker,NULL,"Refresh interrupt");
  while(!Bt(&waiter->task_flags,TASKf_IDLE)||
      !Bt(&rf_waitdoc->flags,DOCf_DO_FULL_REFRESH))Yield;
  Kill(waiter,TRUE);
  while(TaskValidate(waiter))Yield;
  Suspend(sys_winmgr_task,FALSE);DocDel(rf_waitdoc);
  return rf_leaked;
}
I64 *result=CAlloc(16);
Report("REFRESH active begin\n");
result[0]=RFActive;Report("REFRESH active done\n");
result[1]=RFInterrupted;Report("REFRESH interrupt done\n");
U8 *message=MStrPrint("EXPORT refresh-lifetime.bin %X %X\n",result,16);
Report(message);Free(message);
Report("DONE original Refresh lifetime\n");
