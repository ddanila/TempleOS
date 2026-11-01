I64 USSeen;
CTask *USCaller;
I64 USContract()
{
  CTask *old_focus=sys_focus_task,*task;
  CDoc *doc;
  U8 *welcome,*saved,*line;
  I64 result=0,size=0,saved_size=0,deadline;
  Bool killed;
  USSeen=0;USCaller=NULL;
  task=User;
  if(!task)return 0;
  doc=DocPut(task);
  if(doc&&doc==DocDisplay(task))result|=1;
  if(doc&&doc->max_entries==4096)result|=2;
  if(task->border_doc&&task->cur_menu)result|=4;
  line=MStrPrint("USER FLAGS %X %X %X\n",task->display_flags,task->win_inhibit,WIG_USER_TASK_DFT);Report(line);Free(line);
  if(Bt(&task->display_flags,DISPLAYf_SHOW)&&
     Bt(&task->display_flags,DISPLAYf_NOT_RAW)&&
     !Bt(&task->display_flags,DISPLAYf_NO_BORDER)&&!task->win_inhibit)result|=8;
  if(doc&&doc->right_click_link)result|=16;
  XTalk(task,"*(0x%X)(I64 *)=42;*(0x%X)(CTask **)=Fs;\n",&USSeen,&USCaller);
  deadline=cnts.jiffies+2000;
  while(USSeen!=42&&cnts.jiffies<deadline)Yield;
  if(USSeen==42&&USCaller==task)result|=32;
  welcome=FileRead("::/Doc/Start.DD",&size);
  if(doc)saved=DocSave(doc,&saved_size);else saved=NULL;
  if(welcome&&saved&&saved_size>=size&&!MemCmp(welcome,saved,size))result|=64;
  Free(welcome);Free(saved);
  killed=Kill(task);
  if(killed)result|=128;
  if(TaskValidate(old_focus))WinFocus(old_focus);
  line=MStrPrint("USER START MASK %d\n",result);Report(line);Free(line);
  return result;
}
I64 USCheck(){I64 v=USContract;if(v!=255)throw('UserInit',TRUE);return v;}
