CTask *uh_seen;I64 uh_count;
U0 UserStartUp()
{
  DocTermNew;
  DocPrint(,"CUSTOM USER STARTUP\n");
  LBts(&Fs->display_flags,DISPLAYf_SHOW);
  uh_seen=Fs;uh_count++;
}
I64 UserHookContract()
{
  I64 mask=0,deadline=cnts.jiffies+10000,size;
  CTask *old_focus=sys_focus_task,*task;
  CDoc *doc;
  CCtrl *h,*v;
  U8 *saved;
  uh_seen=NULL;uh_count=0;
  task=Spawn(&UserCmdLine,NULL,"CustomUser",-1,Fs,131072);
  while(!uh_seen && cnts.jiffies<deadline)Yield;
  TaskWait(task,TRUE);
  if(uh_seen==task && uh_count==1)mask|=1;
  doc=DocPut(task);
  if(doc && doc==DocDisplay(task) && doc->max_entries==4096 && doc->right_click_link)mask|=2;
  if(task->border_doc && task->cur_menu && Bt(&task->display_flags,DISPLAYf_SHOW) && Bt(&task->display_flags,DISPLAYf_NOT_RAW))mask|=4;
  h=CtrlFindUnique(task,CTRLT_WIN_HSCROLL);v=CtrlFindUnique(task,CTRLT_WIN_VSCROLL);
  if(h && v && h->win_task==task && v->win_task==task)mask|=8;
  saved=DocSave(doc,&size);
  if(saved && size>=20 && !MemCmp(saved,"CUSTOM USER STARTUP\n",20) && !StrMatch("Public Domain",saved) && !StrMatch("HolyC console",saved))mask|=16;
  Free(saved);
  if(Kill(task))mask|=32;
  if(TaskValidate(old_focus))WinFocus(old_focus);
  return mask;
}
