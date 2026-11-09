CTask *cl_owner,*cl_worker;
CCtrl *cl_control;
I64 cl_mode,cl_stage,cl_number,cl_updates,cl_masks[5],cl_mouse[3],cl_target[2],cl_windows[5][4];
Bool cl_release,cl_entered,cl_returned;
U0 CLLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 CLExport(U8 *name,U8 *data,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);CLLog(s);Free(s);}
U0 CLClick(CCtrl *c,I64,I64,Bool down)
{
  U8 *s;
  if(!down || cl_stage)return;
  cl_stage=1;cl_worker=Fs;cl_number=Fs->task_num;cl_updates=winmgr.updates;
  cl_entered=Fs==sys_winmgr_task && c->win_task==cl_owner && TaskValidate(cl_owner) && GetRFlags&0x200;
  s=MStrPrint("CL ENTER %d\n",cl_mode);CLLog(s);Free(s);
  if(!cl_mode)throw('CtrlLife',TRUE);
  if(cl_mode==1)Exit;
  if(cl_mode==2){Fs->task_end_cb=NULL;Exit;}
  if(cl_mode==3)Fs->task_end_cb=NULL;
  while(TRUE)Yield;
  cl_returned=TRUE;
}
U0 CLOwner(U8 *)
{
  U8 *s;
  WinBorder(TRUE);WinHorz(10,65);WinVert(8,48);
  LBts(&Fs->display_flags,DISPLAYf_SHOW);LBts(&Fs->display_flags,DISPLAYf_NOT_RAW);
  Fs->win_inhibit&=~(WIF_SELF_CTRLS|WIF_SELF_FOCUS|WIF_FOCUS_TASK_CTRLS);
  Fs->put_doc=Fs->display_doc=DocNew("ControlLife.DD");
  Fs->put_doc->flags|=DOCF_NO_SCROLL_BARS;DocPrint(Fs->put_doc,"Control lifetime\n");
  cl_control->win_task=Fs;QueIns(cl_control,Fs->last_ctrl);WinToTop(Fs);WinFocus(Fs);
  TaskDerivedValsUpdate(Fs);Sleep(250);
  cl_target[0]=cl_control->scrn_left+12;cl_target[1]=cl_control->scrn_top+12;
  s=MStrPrint("control-life-target-%d.bin",cl_mode);CLExport(s,cl_target,16);Free(s);
  cl_windows[cl_mode][0]=Fs->display_flags;cl_windows[cl_mode][1]=Fs->win_inhibit;
  cl_windows[cl_mode][2]=sys_focus_task==Fs;cl_windows[cl_mode][3]=WinInside(cl_target[0],cl_target[1],Fs);
  s=MStrPrint("control-life-window-%d.bin",cl_mode);CLExport(s,cl_windows[cl_mode],32);Free(s);
  s=MStrPrint("CL READY %d\n",cl_mode);CLLog(s);Free(s);
  while(!cl_release && !(cl_mode>=3 && cl_stage)) {
    cl_mouse[0]=ms.pos.x;cl_mouse[1]=ms.pos.y;cl_mouse[2]=ms.lb+2*ms.rb;Yield;
  }
}
U0 ControlMouseLifetime(U8 *)
{
  I64 before,deadline,mask;Bool replacement;CTask *head=(&Fs->next_child_task)(U8 *)-offset(CTask.next_sibling_task);
  U8 *s;
  LBtr(&Fs->display_flags,DISPLAYf_SHOW);
  s=MStrPrint("CL STATE %X\n",cl_mouse);CLLog(s);Free(s);
  MemSet(cl_masks,0,sizeof(cl_masks));
  for(cl_mode=0;cl_mode<5;cl_mode++) {
    replacement=cl_mode==2 || cl_mode==3;
    before=Fs->data_heap->used_u8s;mask=0;
    cl_stage=0;cl_entered=cl_returned=cl_release=FALSE;cl_worker=NULL;
    cl_control=CAlloc(sizeof(CCtrl));cl_control->flags=CTRLF_SHOW|CTRLF_CAPTURE_LEFT_MS;
    cl_control->type=CTRLT_GENERIC;cl_control->left=40;cl_control->right=80;
    cl_control->top=30;cl_control->bottom=60;cl_control->left_click=&CLClick;
    cl_control->state=0x1234567;
    cl_owner=Spawn(&CLOwner,NULL,"Control lifetime owner",-1,Fs,16384);
    deadline=cnts.jiffies+20000;
    while(!cl_stage && cnts.jiffies<deadline)Yield;
    if(cl_entered)mask|=1;
    if(cl_stage && !cl_returned)mask|=2;
    while(cnts.jiffies<deadline &&
        (!TaskValidate(sys_winmgr_task) || winmgr.updates<cl_updates+2 ||
         replacement && sys_winmgr_task->task_num==cl_number || ms.lb))Yield;
    if(TaskValidate(sys_winmgr_task) && winmgr.updates>=cl_updates+2 &&
        (!replacement || sys_winmgr_task->task_num!=cl_number))mask|=4;
    if(!ms.lb)mask|=128;
    cl_release=TRUE;
    while(Fs->next_child_task!=head && cnts.jiffies<deadline)Yield;
    if(Fs->next_child_task==head && Fs->last_child_task==head && !TaskValidate(cl_owner))mask|=8;
    if(cl_control->next==cl_control && cl_control->last==cl_control && !cl_control->win_task &&
        cl_control->state==0x1234567 && cl_control->flags==(CTRLF_SHOW|CTRLF_CAPTURE_LEFT_MS))mask|=16;
    if(replacement && (!TaskValidate(cl_worker) || cl_worker->task_num!=cl_number) ||
        !replacement && TaskValidate(cl_worker) && cl_worker->task_num==cl_number)mask|=64;
    if(mask==223) {
      Free(cl_control);if(Fs->data_heap->used_u8s==before)mask|=32;
    }
    cl_masks[cl_mode]=mask;
    if(mask!=255)break;
  }
  CLExport("control-life-masks.bin",cl_masks,sizeof(cl_masks));CLLog("CL DONE\n");
}
U0 ControlMouseLifetimeRun()
{
  CTask *controller=Spawn(&ControlMouseLifetime,NULL,"Control mouse lifetime",-1,Fs,32768);
  while(TaskValidate(controller))Yield;
}
