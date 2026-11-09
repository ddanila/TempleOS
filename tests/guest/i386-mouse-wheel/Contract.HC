CTask *wh_owner;
I64 wh_phase,wh_count,wh_sum,wh_last,wh_second,wh_rows[8][7],wh_calls[16][5],wh_mask;
Bool wh_good;
U0 WHLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 WHWheel(CCtrl *c,I64 delta)
{
  I64 *r;
  if(wh_count>=16)throw('WheelCnt',TRUE);
  r=wh_calls[wh_count++];r[0]=wh_phase;r[1]=delta;r[2]=Fs==sys_winmgr_task;
  r[3]=TaskValidate(c->win_task)&&c->win_task==wh_owner;r[4]=(GetRFlags&0x200)!=0;
  if(!r[2] || !r[3] || !r[4])wh_good=FALSE;
  wh_sum+=delta;wh_last=delta;Yield;
}
U0 WHSecond(CCtrl *,I64){wh_second++;}
U0 MouseWheelContract()
{
  CDoc *put=DocPut,*display=DocDisplay,*doc;
  CTask *focus=sys_focus_task;CCtrl *c,*second;
  I64 before=Fs->data_heap->used_u8s,flags=Fs->display_flags,inhibit=Fs->win_inhibit;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  I64 ch,deadline,*r;U8 *s;
  Bool bordered=!Bt(&Fs->display_flags,DISPLAYf_NO_BORDER),ac_old=AutoComplete(FALSE);
  wh_owner=Fs;wh_count=wh_sum=wh_last=wh_second=wh_mask=0;wh_good=TRUE;
  MemSet(wh_rows,0,sizeof(wh_rows));MemSet(wh_calls,0,sizeof(wh_calls));
  WinBorder(TRUE);WinHorz(10,65);WinVert(8,48);LBts(&Fs->display_flags,DISPLAYf_SHOW);
  LBts(&Fs->display_flags,DISPLAYf_NOT_RAW);LBts(&Fs->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);
  Fs->win_inhibit&=~(WIF_SELF_FOCUS|WIF_SELF_CTRLS|WIF_FOCUS_TASK_CTRLS);
  doc=DocNew("MouseWheel.DD");doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;
  DocPrint(doc,"Wheel input\n");DocTop(doc);Fs->put_doc=Fs->display_doc=doc;
  second=CAlloc(sizeof(CCtrl));second->type=CTRLT_GENERIC;second->flags=CTRLF_SHOW;
  second->win_task=Fs;second->wheel_chg=&WHSecond;QueIns(second,&Fs->next_ctrl);
  c=CAlloc(sizeof(CCtrl));c->type=CTRLT_GENERIC;c->flags=CTRLF_SHOW;c->win_task=Fs;
  c->left=40;c->right=80;c->top=30;c->bottom=60;c->wheel_chg=&WHWheel;QueIns(c,&Fs->next_ctrl);
  WinFocus(Fs);
  for(wh_phase=0;wh_phase<8;wh_phase++) {
    Fs->win_inhibit&=~(WIF_SELF_CTRLS|WIF_FOCUS_TASK_CTRLS);
    if(wh_phase==3)Fs->win_inhibit|=WIF_SELF_CTRLS;
    if(wh_phase==5)Fs->win_inhibit|=WIF_FOCUS_TASK_CTRLS;
    TaskDerivedValsUpdate(Fs);Sleep(250);FlushMsgs;
    s=MStrPrint("WH READY %d\n",wh_phase);WHLog(s);Free(s);
    deadline=cnts.jiffies+20000;ch=0;
    while(ch!='n' && cnts.jiffies<deadline){ScanKey(&ch);Sleep(10);}
    if(ch!='n')throw('WhlWait',TRUE);Sleep(250);
    r=wh_rows[wh_phase];r[0]=ms.pos.z;r[1]=ms.has_wheel;r[2]=wh_count;r[3]=wh_sum;r[4]=wh_last;
    r[5]=Bt(&Fs->win_inhibit,WIf_SELF_CTRLS);r[6]=Bt(&Fs->win_inhibit,WIf_FOCUS_TASK_CTRLS);
  }
  QueRem(c);QueRem(second);Free(c);Free(second);
  Fs->put_doc=put;Fs->display_doc=display;DocDel(doc);Fs->win_inhibit=inhibit;
  WinBorder(bordered);WinHorz(left,right);WinVert(top,bottom);Fs->display_flags=flags;
  if(TaskValidate(focus))WinFocus(focus);FlushMsgs;
  if(Fs->put_doc==put&&Fs->display_doc==display&&Fs->win_inhibit==inhibit)wh_mask|=1;
  if(Fs->data_heap->used_u8s==before)wh_mask|=2;
  if(!wh_second)wh_mask|=4;
  if(wh_good)wh_mask|=8;
  AutoComplete(ac_old);
  s=MStrPrint("EXPORT wheel-rows.bin %X %X\n",wh_rows,sizeof(wh_rows));WHLog(s);Free(s);
  s=MStrPrint("EXPORT wheel-calls.bin %X %X\n",wh_calls,wh_count*40);WHLog(s);Free(s);
  s=MStrPrint("EXPORT wheel-mask.bin %X 8\n",&wh_mask);WHLog(s);Free(s);WHLog("WH DONE\n");
}
