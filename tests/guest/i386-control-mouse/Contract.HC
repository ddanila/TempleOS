CTask *cm_parent;
I64 cm_phase,cm_count,cm_rows[2048][8],cm_geometry[8][7],cm_state[3],cm_mask;
U0 CMLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 CMExport(U8 *name,U8 *data,I64 size)
{U8 *s=MStrPrint("EXPORT %s %X %X\n",name,data,size);CMLog(s);Free(s);}
U0 CMTrack(U8 *)
{while(TRUE){cm_state[0]=ms.pos.x;cm_state[1]=ms.pos.y;cm_state[2]=ms.lb+2*ms.rb;Yield;}}
U0 CMClick(CCtrl *c,I64 x,I64 y,Bool down,I64 side)
{
  I64 *r;
  if(cm_count<2048) {
    r=cm_rows[cm_count++];r[0]=cm_phase;r[1]=side;r[2]=down;r[3]=x;r[4]=y;
    r[5]=Fs==sys_winmgr_task;r[6]=TaskValidate(c->win_task)&&c->win_task==cm_parent;
    r[7]=(GetRFlags&0x200)!=0;
  }
  Yield;
}
U0 CMLeft(CCtrl *c,I64 x,I64 y,Bool down){CMClick(c,x,y,down,0);}
U0 CMRight(CCtrl *c,I64 x,I64 y,Bool down){CMClick(c,x,y,down,1);}
U0 ControlMouseContract()
{
  CDoc *put=DocPut,*display=DocDisplay,*doc;
  CTask *focus=sys_focus_task,*tracker,*first=Fs->next_child_task,*last=Fs->last_child_task;
  CCtrl *c;
  I64 before=Fs->data_heap->used_u8s,inhibit=Fs->win_inhibit,flags=Fs->display_flags;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  I64 ch,deadline,*g;U8 *s;
  Bool bordered=!Bt(&Fs->display_flags,DISPLAYf_NO_BORDER),old_ac=AutoComplete(FALSE);
  cm_parent=Fs;cm_phase=cm_count=cm_mask=0;MemSet(cm_rows,0,sizeof(cm_rows));
  WinBorder(TRUE);WinHorz(10,65);WinVert(8,48);
  LBts(&Fs->display_flags,DISPLAYf_SHOW);LBts(&Fs->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);
  Fs->win_inhibit&=~(WIF_SELF_CTRLS|WIF_FOCUS_TASK_CTRLS|WIF_SELF_FOCUS);
  doc=DocNew("ControlMouse.DD");doc->flags|=DOCF_NO_SCROLL_BARS;
  DocPrint(doc,"Control callback input\n");DocTop(doc);Fs->put_doc=Fs->display_doc=doc;
  c=CAlloc(sizeof(CCtrl));c->type=CTRLT_GENERIC;c->win_task=Fs;
  c->left=40;c->right=80;c->top=30;c->bottom=60;c->left_click=&CMLeft;c->right_click=&CMRight;
  QueIns(c,Fs->last_ctrl);WinFocus(Fs);
  tracker=Spawn(&CMTrack,NULL,"Control mouse tracker",-1,Fs,16384);
  s=MStrPrint("CM STATE %X\n",cm_state);CMLog(s);Free(s);
  for(cm_phase=0;cm_phase<8;cm_phase++) {
    c->flags=CTRLF_SHOW;
    if(cm_phase==2 || cm_phase==3 || cm_phase==5)c->flags|=CTRLF_BORDER;
    if(cm_phase==4)c->flags|=CTRLF_CAPTURE_LEFT_MS;
    if(cm_phase==5)c->flags|=CTRLF_CAPTURE_RIGHT_MS;
    Fs->win_inhibit&=~(WIF_SELF_CTRLS|WIF_FOCUS_TASK_CTRLS);
    if(cm_phase==6)Fs->win_inhibit|=WIF_SELF_CTRLS;
    if(cm_phase==7)Fs->win_inhibit|=WIF_FOCUS_TASK_CTRLS;
    TaskDerivedValsUpdate(Fs);Sleep(250);FlushMsgs;
    g=cm_geometry[cm_phase];g[0]=Fs->pix_left;g[1]=Fs->pix_top;g[2]=c->flags;
    g[3]=c->scrn_left+12;g[4]=c->scrn_top+12;
    g[5]=Fs->pix_left+220;g[6]=Fs->pix_top+120;
    s=MStrPrint("control-target-%d.bin",cm_phase);CMExport(s,g,7*8);Free(s);
    s=MStrPrint("CM READY %d\n",cm_phase);CMLog(s);Free(s);
    deadline=cnts.jiffies+20000;ch=0;
    while(ch!='n' && cnts.jiffies<deadline){ScanKey(&ch);Yield;}
    if(ch!='n')break;
  }
  if(cm_phase==8)cm_mask|=1;
  Fs->win_inhibit=inhibit;QueRem(c);Free(c);
  Fs->put_doc=put;Fs->display_doc=display;DocDel(doc);
  Kill(tracker,TRUE,FALSE);
  deadline=cnts.jiffies+5000;
  while((TaskValidate(tracker)||Fs->next_child_task!=first||Fs->last_child_task!=last) && cnts.jiffies<deadline)Yield;
  if(!TaskValidate(tracker)&&Fs->next_child_task==first&&Fs->last_child_task==last)cm_mask|=2;
  WinBorder(bordered);WinHorz(left,right);WinVert(top,bottom);Fs->display_flags=flags;
  if(TaskValidate(focus))WinFocus(focus);
  if(Fs->put_doc==put&&Fs->display_doc==display&&Fs->win_inhibit==inhibit)cm_mask|=4;
  if(Fs->data_heap->used_u8s==before)cm_mask|=8;
  AutoComplete(old_ac);
  CMExport("control-rows.bin",cm_rows,cm_count*8*8);
  CMExport("control-mask.bin",&cm_mask,8);CMLog("CM DONE\n");
}
