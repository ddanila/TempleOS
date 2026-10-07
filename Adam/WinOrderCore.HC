#ifndef I386_WIN_ORDER_TRACE
U0 WinOrderTrace(U8 *phase,CTask *task) {}
#endif
#ifndef I386_WIN_CHILD_HEAD_DECLARED
CTask *WinOrderChildHead(CTask *task) { return &task->next_child_task; }
#endif
I64 WinOnTopWindows()
{
  CTask *task,*task1,*first_moved_fwd=NULL;
  I64 res=0,old_flags=GetRFlags;
  SetRFlags(old_flags&~512); //TODO Multiprocessor safe
  WinOrderTrace("scan begin",sys_winmgr_task);
  task=sys_winmgr_task->next_task;
  while (task!=sys_winmgr_task && task!=first_moved_fwd) {
    WinOrderTrace("scan node",task);
    task1=task->next_task;
    if (!TaskValidate(task)) {
      SetRFlags(old_flags);
      return res;
    }
    if (Bt(&task->display_flags,DISPLAYf_WIN_ON_TOP) &&
	  task!=sys_winmgr_task->last_task) {
      TaskQueRem(task);
      TaskQueIns(task,sys_winmgr_task);
      res++;
      if (!first_moved_fwd)
	first_moved_fwd=task;
    }
    task=task1;
  }
  SetRFlags(old_flags);
  return res;
}

public I64 WinToTop(CTask *task=NULL,Bool update_z_buf=TRUE)
{//Put task's win on top of window stack.
  CTask *task1;
  I64 res=0,old_flags=GetRFlags;
  if (!task) task=Fs;
  if (!TaskValidate(task) || task->gs->num)
    return 0;
  WinOrderTrace("derive begin",task);
  TaskDerivedValsUpdate(task,FALSE);
  WinOrderTrace("derive end",task);
  if (!sys_winmgr_task || task==sys_winmgr_task)
    return 0;
  SetRFlags(old_flags&~512);
  if (!TaskValidate(task)) {
    SetRFlags(old_flags);
    return 0;
  }
  if (task!=sys_winmgr_task->last_task) {
    WinOrderTrace("move begin",task);
    TaskQueRem(task);
    TaskQueIns(task,sys_winmgr_task);
    WinOrderTrace("move end",task);
    res++;
  }
  if (!Bt(&task->win_inhibit,WIf_SELF_FOCUS))
    sys_focus_task=task;
  if (res && !Bt(&task->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP)) {
    task1=task->next_child_task;
    while (task1!=WinOrderChildHead(task)) {
      if (!TaskValidate(task1))
	break;
      WinOrderTrace("raise child",task1);
      res+=WinToTop(task1,FALSE);
      task1=task1->next_sibling_task;
    }
    if (task->popup_task &&
	  task->popup_task->parent_task==task)
      res+=WinToTop(task->popup_task,FALSE);
  }
  SetRFlags(old_flags);
  WinOrderTrace("scan call",task);
  res+=WinOnTopWindows;
  WinOrderTrace("top done",task);
  if (res && update_z_buf)
    WinZBufUpdate;
  return res;
}
