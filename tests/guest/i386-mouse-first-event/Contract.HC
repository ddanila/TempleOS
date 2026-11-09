I64 mf_phase,mf_count,mf_calls[32][4],mf_rows[8][3],mf_mode[2],mf_initial[3],mf_trace[8][12],mf_mask;
Bool mf_good;
U0 MFLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 MouseFirstEvent(Bool raw=FALSE)
{
  CDoc *put=DocPut,*display=DocDisplay,*doc;CTask *focus=sys_focus_task;
  I64 before=Fs->data_heap->used_u8s,flags=Fs->display_flags,inhibit=Fs->win_inhibit;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  I64 old_x=ms.pos.x,old_y=ms.pos.y,old_z=ms.pos.z,old_lb=ms.lb,old_rb=ms.rb;
  I64 ch,deadline,irq,code,a,b,*r;U8 *s;F64 now;CCtrl *control;
  Bool bordered=!Bt(&Fs->display_flags,DISPLAYf_NO_BORDER),ac_old=AutoComplete(FALSE);
  mf_count=mf_mask=0;mf_good=TRUE;
  MemSet(mf_rows,0,sizeof(mf_rows));MemSet(mf_calls,0,sizeof(mf_calls));
  WinBorder(TRUE);WinHorz(10,65);WinVert(8,48);LBts(&Fs->display_flags,DISPLAYf_SHOW);
  LBEqu(&Fs->display_flags,DISPLAYf_NOT_RAW,!raw);LBts(&Fs->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);
  Fs->win_inhibit&=~WIF_SELF_FOCUS;Fs->win_inhibit|=WIF_SELF_MS_L|WIF_SELF_MS_R;
  doc=DocNew("MouseFirstEvent.DD");doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;
  DocPrint(doc,"Synthetic mouse messages\n");DocTop(doc);Fs->put_doc=Fs->display_doc=doc;WinFocus(Fs);
  mf_mode[0]=raw;mf_mode[1]=!Bt(&Fs->display_flags,DISPLAYf_NOT_RAW);
  Sleep(250);mf_initial[0]=ms.pos.x;mf_initial[1]=ms.pos.y;mf_initial[2]=ms.lb+2*ms.rb;
  for(mf_phase=0;mf_phase<8;mf_phase++) {
    FlushMsgs;mf_trace[mf_phase][0]=winmgr.updates;
    switch(mf_phase) {
      case 0:MsSet(,,,TRUE,FALSE);break;
      case 1:MsSet(,,,FALSE,FALSE);break;
      case 2:MsSet(,,,FALSE,TRUE);break;
      case 3:MsSet(,,,FALSE,FALSE);break;
      case 4:MsSet;break;
      case 5:
        irq=GetRFlags;SetRFlags(irq&~0x200);MsSet(,,,TRUE,FALSE);MsSet(,,,FALSE,FALSE);
        if(GetRFlags&0x200)mf_good=FALSE;SetRFlags(irq);break;
      case 6:MsSet(160,160,0,FALSE,FALSE);break;
      case 7:MsSet(176,184);break;
    }
    if(!(GetRFlags&0x200))mf_good=FALSE;
    Sleep(600);r=mf_trace[mf_phase];r[1]=winmgr.updates;r[2]=GetRFlags;r[3]=sys_focus_task==Fs;
    now=tS;r[4]=now(U64);r[5]=ms.right_dbl_time(U64);r[6]=ms.right_down_sent;r[7]=ms.right_dbl;
    r[8]=ms.left_dbl_time(U64);r[9]=ms.left_down_sent;r[10]=ms.left_dbl;r[11]=0;
    for(control=Fs->next_ctrl;control!=&Fs->next_ctrl;control=control->next)
      if(control->flags&CTRLF_SHOW&&control->scrn_left<=ms.pos.x<=control->scrn_right&&
          control->scrn_top<=ms.pos.y<=control->scrn_bottom)r[11]++;

    while(code=ScanMsg(&a,&b,0x1FF0)) {
      if(mf_count>=32)throw('SetMsgs',TRUE);
      r=mf_calls[mf_count++];r[0]=mf_phase;r[1]=code;r[2]=a;r[3]=b;
    }
    mf_rows[mf_phase][0]=mf_count;mf_rows[mf_phase][1]=ms.lb;mf_rows[mf_phase][2]=ms.rb;
    s=MStrPrint("MF READY %d\n",mf_phase);MFLog(s);Free(s);
    deadline=cnts.jiffies+20000;ch=0;
    while(ch!='n' && cnts.jiffies<deadline){ScanKey(&ch);Sleep(10);}
    if(ch!='n')throw('SetWait',TRUE);
  }
  Fs->put_doc=put;Fs->display_doc=display;DocDel(doc);Fs->win_inhibit=inhibit;
  WinBorder(bordered);WinHorz(left,right);WinVert(top,bottom);Fs->display_flags=flags;
  MsSet(old_x,old_y,old_z,old_lb,old_rb);
  if(TaskValidate(focus))WinFocus(focus);FlushMsgs;
  if(Fs->put_doc==put&&Fs->display_doc==display&&Fs->win_inhibit==inhibit)mf_mask|=1;
  if(Fs->data_heap->used_u8s==before)mf_mask|=2;
  if(mf_good)mf_mask|=4;
  s=MStrPrint("EXPORT first-event-rows.bin %X %X\n",mf_rows,sizeof(mf_rows));MFLog(s);Free(s);
  s=MStrPrint("EXPORT first-event-calls.bin %X %X\n",mf_calls,mf_count*32);MFLog(s);Free(s);
  s=MStrPrint("EXPORT first-event-mask.bin %X 8\n",&mf_mask);MFLog(s);Free(s);
  s=MStrPrint("EXPORT first-event-initial.bin %X 18\n",mf_initial);MFLog(s);Free(s);
  s=MStrPrint("EXPORT first-event-trace.bin %X %X\n",mf_trace,sizeof(mf_trace));MFLog(s);Free(s);
  s=MStrPrint("EXPORT first-event-mode.bin %X 10\n",mf_mode);MFLog(s);Free(s);MFLog("MF DONE\n");
}
