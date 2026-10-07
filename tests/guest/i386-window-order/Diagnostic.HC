U0 WOIdle(U8 *data){while(TRUE)Yield;}
I64 JRContract()
{
  CTask *a,*b,*child,*old_focus=sys_focus_task;
  I64 mask=0;
  a=Spawn(&WOIdle,NULL,"Order A",-1,Fs);
  b=Spawn(&WOIdle,NULL,"Order B",-1,Fs);
  a->win_inhibit=b->win_inhibit=0;
  a->display_flags=b->display_flags=0;
  if(WinToTop(a,FALSE)>0&&sys_winmgr_task->last_task==a)mask|=1;
  if(!WinToTop(a,FALSE))mask|=2;
  LBts(&b->win_inhibit,WIf_SELF_FOCUS);
  WinToTop(b,FALSE);
  if(sys_focus_task==a&&sys_winmgr_task->last_task==b)mask|=4;
  LBtr(&b->win_inhibit,WIf_SELF_FOCUS);
  LBts(&b->display_flags,DISPLAYf_WIN_ON_TOP);
  WinToTop(a,FALSE);
  if(sys_winmgr_task->last_task==b&&sys_focus_task==a)mask|=8;
  LBtr(&b->display_flags,DISPLAYf_WIN_ON_TOP);
  child=Spawn(&WOIdle,NULL,"Order child",-1,a);
  child->win_inhibit=0;child->display_flags=0;
  LBts(&a->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);
  WinToTop(b,FALSE);WinToTop(a,FALSE);
  if(sys_winmgr_task->last_task==a)mask|=16;
  LBtr(&a->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);
  WinToTop(b,FALSE);WinToTop(a,FALSE);
  if(sys_winmgr_task->last_task==child&&sys_focus_task==child)mask|=32;
  sys_focus_task=old_focus;
  Print("WO order complete\n");
  Kill(b);Print("WO B retired\n");
  Kill(a);Print("WO A retired\n");
  return mask;
}
