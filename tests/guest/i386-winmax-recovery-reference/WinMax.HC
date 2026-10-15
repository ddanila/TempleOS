U0 WMHold(U8 *data){while(TRUE)Yield;}
I64 WMTarget()
{
  CTask *old_focus=sys_focus_task,*t;
  I64 l=Fs->win_left,r=Fs->win_right,top=Fs->win_top,b=Fs->win_bottom,ok;
  t=Spawn(&WMHold,NULL,"WinMax target",-1,Fs);
  t->display_flags=0;t->win_inhibit=0;
  WinHorz(7,31,t);WinVert(9,27,t);WinMax(t);
  ok=t->win_left==1&&t->win_right==78&&t->win_top==2&&t->win_bottom==58;
  ok=ok&&Fs->win_left==l&&Fs->win_right==r&&Fs->win_top==top&&Fs->win_bottom==b;
  ok=ok&&sys_focus_task==t&&sys_winmgr_task->last_task==t;
  sys_focus_task=old_focus;Kill(t);WinToTop(Fs);sys_focus_task=old_focus;
  return ok;
}
U0 WMFail(CCtrl *c)
{if(Fs==c->win_task)throw('WMFail',TRUE);}
I64 WMRecover()
{
  I64 flags=GetRFlags,after,l=Fs->win_left,r=Fs->win_right,top=Fs->win_top,b=Fs->win_bottom;
  Bool caught=FALSE,unlocked;
  CCtrl *c=CAlloc(sizeof(CCtrl));
  c->type=CTRLT_GENERIC;c->win_task=Fs;c->update_derived_vals=&WMFail;
  SetRFlags(flags&~512);QueIns(c,Fs->last_ctrl);
  SetRFlags(flags|512);
  try {WinMax;}
  catch {caught=Fs->except_ch=='WMFail';Fs->catch_except=TRUE;}
  after=GetRFlags;SetRFlags(flags&~512);QueRem(c);Free(c);
  unlocked=!Bt(&Fs->task_flags,TASKf_TASK_LOCK);
  SetRFlags(flags);WinHorz(l,r);WinVert(top,b);
  if(!caught||!unlocked)return -1;
  return (after>>9)&1;
}
