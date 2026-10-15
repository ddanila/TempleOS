#ifndef REFRESH_SLEEP
#define REFRESH_SLEEP Sleep
#endif
#ifndef REFRESH_JIFFIES
#define REFRESH_JIFFIES cnts.jiffies
#endif
#ifndef REFRESH_SCOPE_LOCAL
#define REFRESH_SCOPE_LOCAL
#define REFRESH_SCOPE_OPEN
#define REFRESH_SCOPE_RELEASE RefreshRestoreCore(Fs,old_doc,old_idle,old_full_refresh,&idle_saved,&full_saved)
#define REFRESH_SCOPE_CLOSE
#endif
U0 RefreshRestoreCore(CTask *task,CDoc *doc,Bool old_idle,Bool old_full_refresh,
  Bool *idle_saved,Bool *full_saved)
{
  if(*full_saved) {
    *full_saved=FALSE;
    LBEqu(&doc->flags,DOCf_DO_FULL_REFRESH,old_full_refresh);
  }
  if(*idle_saved) {
    *idle_saved=FALSE;
    LBEqu(&task->task_flags,TASKf_IDLE,old_idle);
  }
}
public U0 Refresh(I64 cnt=1,Bool force=FALSE)
{//Wait for WinMgr; native scope hooks additionally cover committed task Exit.
  Bool old_full_refresh=FALSE,old_idle=FALSE,idle_saved=FALSE,full_saved=FALSE;
  CDoc *old_doc=DocPut;
  I64 update_cnt;
  REFRESH_SCOPE_LOCAL;
  try {
    REFRESH_SCOPE_OPEN;
    old_idle=LBts(&Fs->task_flags,TASKf_IDLE);idle_saved=TRUE;
    if(!cnt&&force)LBts(&sys_semas[SEMA_JUST_PUMP_MSGS],0);
    while(Bt(&sys_semas[SEMA_REFRESH_IN_PROGRESS],0)) {
      if(force&&sys_winmgr_task)sys_winmgr_task->wake_jiffy=REFRESH_JIFFIES;
      Yield;
    }
    if(cnt>1&&old_doc) {
      old_full_refresh=LBts(&old_doc->flags,DOCf_DO_FULL_REFRESH);full_saved=TRUE;
    }
    update_cnt=winmgr.updates+cnt;
    while(winmgr.updates<update_cnt) {
      if(force&&sys_winmgr_task)sys_winmgr_task->wake_jiffy=REFRESH_JIFFIES;
      REFRESH_SLEEP(1);
    }
    REFRESH_SCOPE_RELEASE;
    REFRESH_SCOPE_CLOSE;
  } catch {
    REFRESH_SCOPE_RELEASE;
    REFRESH_SCOPE_CLOSE;
  }
}
