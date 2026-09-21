I64 window_check_calls;
Bool window_check_throw;
U0 WindowCheckUpdate(CCtrl *c)
{
  window_check_calls++;
  c->right=c->win_task->pix_width-2;
  if(window_check_throw) throw('WinCtrl',TRUE);
}
Bool WindowCheckInside(CCtrl *c,I64 x,I64 y)
{ return x==y+1; }
I64 WindowServiceCheck()
{
  CTask task;
  CCtrl a,b;
  I64 flags=GetRFlags,px=gr.pan_text_x,py=gr.pan_text_y,result=14,caught=0,n;
  MemSet(&task,0,sizeof(task)); MemSet(&a,0,sizeof(a)); MemSet(&b,0,sizeof(b));
  task.addr=&task; task.task_signature=TASK_SIGNATURE_VAL;
  QueInit(&task.next_ctrl);
  task.win_left=2; task.win_right=9; task.win_top=3; task.win_bottom=7;
  a.win_task=b.win_task=&task; a.type=b.type=CTRLT_GENERIC;
  a.left=1; a.top=3; a.bottom=4; a.flags=CTRLF_SHOW;
  a.update_derived_vals=&WindowCheckUpdate;
  b.left=5; b.right=6; b.top=7; b.bottom=8; b.flags=CTRLF_SHOW|CTRLF_BORDER;
  QueIns(&a,task.last_ctrl); QueIns(&b,task.last_ctrl);
  window_check_calls=0; window_check_throw=FALSE;
  gr.pan_text_x=2; gr.pan_text_y=-3;
  TaskDerivedValsUpdate(&task,FALSE);
  if(window_check_calls!=1 || task.pix_width!=64 || task.pix_height!=40 ||
      a.scrn_left!=19 || a.scrn_right!=80 || a.scrn_top!=24 ||
      b.scrn_left!=15 || b.scrn_right!=16 || b.scrn_top!=20 || b.scrn_bottom!=21 ||
      (GetRFlags&0x200)!=(flags&0x200) || Bt(&task.task_flags,TASKf_TASK_LOCK)) result=-1;
  if(!TaskValidate(&task) || TaskValidate(NULL) || TaskValidate(0x80000000)) result=-2;
  task.addr=NULL; if(TaskValidate(&task)) result=-2; task.addr=&task;
  task.task_signature=0; if(TaskValidate(&task)) result=-2; task.task_signature=TASK_SIGNATURE_VAL;
  if(CtrlFindUnique(&task,CTRLT_GENERIC)!=&a || CtrlFindUnique(&task,CTRLT_VIEWING_ANGLES)) result=-3;
  if(!CtrlInside(&a,19,24) || CtrlInside(&a,18,24)) result=-4;
  a.inside_ctrl=&WindowCheckInside;
  if(!CtrlInside(&a,3,2) || CtrlInside(&a,2,3)) result=-4;
  a.flags=0; if(CtrlInside(&a,3,2)) result=-4; a.flags=CTRLF_SHOW;
  if(WinInside(16,24,&task)) result=-5;
  task.display_flags=1<<DISPLAYf_SHOW;
  if(!WinInside(16,24,&task) || !WinInside(8,16,&task,8) || WinInside(7,16,&task,8)) result=-5;
  LBts(&task.display_flags,DISPLAYf_NO_BORDER);
  if(WinInside(8,16,&task,8)) result=-5;
  n=window_check_calls;
  if(WinHorz(2,9,&task) || WinVert(3,7,&task) || window_check_calls!=n) result=-6;
  if(!WinHorz(90,95,&task) || task.win_left!=79 || task.win_right!=84 || task.pix_width!=48) result=-7;
  if(!WinHorz(-10,-2,&task) || task.win_left!=-8 || task.win_right!=0 || task.pix_width!=72) result=-8;
  if(!WinHorz(4,2,&task) || task.win_left!=4 || task.win_right!=4 || task.pix_width!=8) result=-9;
  if(!WinVert(70,75,&task) || task.win_top!=59 || task.win_bottom!=64 || task.pix_height!=48) result=-10;
  if(!WinVert(-10,-2,&task) || task.win_top!=-7 || task.win_bottom!=1 || task.pix_height!=72) result=-11;
  if(!WinVert(5,2,&task) || task.win_top!=5 || task.win_bottom!=5 || task.pix_height!=8) result=-12;
  SetRFlags(flags&~0x200);
  TaskDerivedValsUpdate(&task,FALSE);
  if(GetRFlags&0x200 || Bt(&task.task_flags,TASKf_TASK_LOCK)) result=-13;
  SetRFlags(flags);
  window_check_throw=TRUE;
  try { WinHorz(2,10,&task); }
  catch { if(Fs->except_ch=='WinCtrl') { Fs->catch_except=TRUE; caught++; } }
  window_check_throw=FALSE;
  if(caught!=1 || Bt(&task.task_flags,TASKf_TASK_LOCK) || (GetRFlags&0x200)!=(flags&0x200) ||
      !WinHorz(2,11,&task) || task.pix_width!=80) result=-14;
  QueRem(&a); QueRem(&b);
  gr.pan_text_x=px; gr.pan_text_y=py; SetRFlags(flags);
  return result;
}
