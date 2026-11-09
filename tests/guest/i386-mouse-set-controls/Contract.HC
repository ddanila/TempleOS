CTask *mc_owner;
I64 mc_phase,mc_count,mc_calls[16][8],mc_rows[9][3],mc_mask;
Bool mc_good;
U0 MCLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 MCCall(CCtrl *c,I64 x,I64 y,Bool down,Bool right)
{
  I64 *r;
  if(mc_count>=16)throw('SetCalls',TRUE);
  r=mc_calls[mc_count++];r[0]=mc_phase;r[1]=x;r[2]=y;r[3]=down;r[4]=right;
  r[5]=Fs==sys_winmgr_task;r[6]=TaskValidate(c->win_task)&&c->win_task==mc_owner;
  r[7]=(GetRFlags&0x200)!=0;Yield;
}
U0 MCLeft(CCtrl *c,I64 x,I64 y,Bool down){MCCall(c,x,y,down,FALSE);}
U0 MCRight(CCtrl *c,I64 x,I64 y,Bool down){MCCall(c,x,y,down,TRUE);}
U0 MouseSetControls()
{
  CDoc *put=DocPut,*display=DocDisplay,*doc;CTask *focus=sys_focus_task;CCtrl *c;
  I64 before=Fs->data_heap->used_u8s,flags=Fs->display_flags,inhibit=Fs->win_inhibit;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  I64 old_x=ms.pos.x,old_y=ms.pos.y,old_z=ms.pos.z,old_lb=ms.lb,old_rb=ms.rb;
  I64 x,y,ch,deadline,irq;U8 *s;
  Bool bordered=!Bt(&Fs->display_flags,DISPLAYf_NO_BORDER),ac_old=AutoComplete(FALSE);
  mc_owner=Fs;mc_count=mc_mask=0;mc_good=TRUE;
  MemSet(mc_rows,0,sizeof(mc_rows));MemSet(mc_calls,0,sizeof(mc_calls));
  WinBorder(TRUE);WinHorz(10,65);WinVert(8,48);LBts(&Fs->display_flags,DISPLAYf_SHOW);
  LBts(&Fs->display_flags,DISPLAYf_NOT_RAW);LBts(&Fs->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);
  Fs->win_inhibit&=~(WIF_SELF_FOCUS|WIF_SELF_CTRLS|WIF_FOCUS_TASK_CTRLS);
  doc=DocNew("MouseSetControls.DD");doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;
  DocPrint(doc,"Synthetic mouse control input\n");DocTop(doc);Fs->put_doc=Fs->display_doc=doc;
  c=CAlloc(sizeof(CCtrl));c->type=CTRLT_GENERIC;c->flags=CTRLF_SHOW;c->win_task=Fs;
  c->left=40;c->right=80;c->top=30;c->bottom=60;c->left_click=&MCLeft;c->right_click=&MCRight;
  QueIns(c,&Fs->next_ctrl);WinFocus(Fs);TaskDerivedValsUpdate(Fs);Sleep(250);
  x=c->scrn_left+12;y=c->scrn_top+12;
  for(mc_phase=0;mc_phase<9;mc_phase++) {
    FlushMsgs;irq=GetRFlags;SetRFlags(irq&~0x200);
    switch(mc_phase) {
      case 0:MsSet(x,y,0,FALSE,FALSE);break;
      case 1:MsSet(,,,TRUE,FALSE);break;
      case 2:MsSet(,,,FALSE,FALSE);break;
      case 3:MsSet(,,,FALSE,TRUE);break;
      case 4:MsSet(,,,FALSE,FALSE);break;
      case 5:MsSet(,,,TRUE,FALSE);MsSet(,,,FALSE,FALSE);break;
      case 6:MsSet(x+100,y,,TRUE,FALSE);MsSet(x,y,,FALSE,FALSE);break;
      case 7:MsSet(,,,TRUE,TRUE);break;
      case 8:MsSet(,,,FALSE,FALSE);break;
    }
    if(GetRFlags&0x200)mc_good=FALSE;SetRFlags(irq);Sleep(250);
    s=MStrPrint("MC READY %d\n",mc_phase);MCLog(s);Free(s);
    deadline=cnts.jiffies+20000;ch=0;
    while(ch!='n' && cnts.jiffies<deadline){ScanKey(&ch);Sleep(10);}
    if(ch!='n')throw('SetWait',TRUE);Sleep(250);
    mc_rows[mc_phase][0]=mc_count;mc_rows[mc_phase][1]=ms.lb;mc_rows[mc_phase][2]=ms.rb;
  }
  QueRem(c);Free(c);Fs->put_doc=put;Fs->display_doc=display;DocDel(doc);Fs->win_inhibit=inhibit;
  WinBorder(bordered);WinHorz(left,right);WinVert(top,bottom);Fs->display_flags=flags;
  MsSet(old_x,old_y,old_z,old_lb,old_rb);
  if(TaskValidate(focus))WinFocus(focus);FlushMsgs;
  if(Fs->put_doc==put&&Fs->display_doc==display&&Fs->win_inhibit==inhibit)mc_mask|=1;
  if(Fs->data_heap->used_u8s==before)mc_mask|=2;
  if(mc_good)mc_mask|=4;
  s=MStrPrint("EXPORT set-control-rows.bin %X %X\n",mc_rows,sizeof(mc_rows));MCLog(s);Free(s);
  s=MStrPrint("EXPORT set-control-calls.bin %X %X\n",mc_calls,mc_count*64);MCLog(s);Free(s);
  s=MStrPrint("EXPORT set-control-mask.bin %X 8\n",&mc_mask);MCLog(s);Free(s);MCLog("MC DONE\n");
}
