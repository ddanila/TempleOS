U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 RFSync(Bool pump)
{
  I64 n=winmgr.updates,m=0;
  Bool idle=Bt(&Fs->task_flags,TASKf_IDLE);
  Refresh(0,pump);
  if(winmgr.updates==n)m|=1;
  if(Bt(&Fs->task_flags,TASKf_IDLE)==idle)m|=2;
  if(Bt(&sys_semas[SEMA_JUST_PUMP_MSGS],0)==pump)m|=4;
  LBtr(&sys_semas[SEMA_JUST_PUMP_MSGS],0);
  return m;
}
I64 RFStep(I64 count,Bool force,Bool idle,Bool full)
{
  I64 n,m=0;
  CDoc *d=DocPut;
  LBEqu(&Fs->task_flags,TASKf_IDLE,idle);
  LBEqu(&d->flags,DOCf_DO_FULL_REFRESH,full);
  if(force)sys_winmgr_task->wake_jiffy=cnts.jiffies+100000;
  n=winmgr.updates;
  Refresh(count,force);
  if(winmgr.updates>=n+count)m|=1;
  if(Bt(&Fs->task_flags,TASKf_IDLE)==idle)m|=2;
  if(Bt(&d->flags,DOCf_DO_FULL_REFRESH)==full)m|=4;
  if(DocPut==d)m|=8;
  LBtr(&Fs->task_flags,TASKf_IDLE);
  LBtr(&d->flags,DOCf_DO_FULL_REFRESH);
  return m;
}
I64 *result=CAlloc(48);
LBtr(&sys_semas[SEMA_JUST_PUMP_MSGS],0);
result[0]=RFSync(FALSE);
result[1]=RFSync(TRUE);
result[2]=RFStep(1,FALSE,FALSE,FALSE);
result[3]=RFStep(2,FALSE,TRUE,FALSE);
result[4]=RFStep(2,FALSE,FALSE,TRUE);
result[5]=RFStep(1,TRUE,FALSE,FALSE);
U8 *message=MStrPrint("EXPORT refresh.bin %X %X\n",result,48);
Report(message);Free(message);
Report("DONE original Refresh modes\n");
