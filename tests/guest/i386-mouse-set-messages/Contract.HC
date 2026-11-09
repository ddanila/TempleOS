I64 mm_phase,mm_count,mm_calls[32][4],mm_rows[8][3],mm_mode[2],mm_mask;
Bool mm_good;
U0 MMLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 MouseSetMessages(Bool raw=FALSE)
{
  CDoc *put=DocPut,*display=DocDisplay,*doc;CTask *focus=sys_focus_task;
  I64 before=Fs->data_heap->used_u8s,flags=Fs->display_flags,inhibit=Fs->win_inhibit;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  I64 old_x=ms.pos.x,old_y=ms.pos.y,old_z=ms.pos.z,old_lb=ms.lb,old_rb=ms.rb;
  I64 ch,deadline,irq,code,a,b,*r;U8 *s;
  Bool bordered=!Bt(&Fs->display_flags,DISPLAYf_NO_BORDER),ac_old=AutoComplete(FALSE);
  mm_count=mm_mask=0;mm_good=TRUE;
  MemSet(mm_rows,0,sizeof(mm_rows));MemSet(mm_calls,0,sizeof(mm_calls));
  WinBorder(TRUE);WinHorz(10,65);WinVert(8,48);LBts(&Fs->display_flags,DISPLAYf_SHOW);
  LBEqu(&Fs->display_flags,DISPLAYf_NOT_RAW,!raw);LBts(&Fs->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);
  Fs->win_inhibit&=~WIF_SELF_FOCUS;Fs->win_inhibit|=WIF_SELF_MS_L|WIF_SELF_MS_R;
  doc=DocNew("MouseSetMessages.DD");doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;
  DocPrint(doc,"Synthetic mouse messages\n");DocTop(doc);Fs->put_doc=Fs->display_doc=doc;WinFocus(Fs);
  mm_mode[0]=raw;mm_mode[1]=!Bt(&Fs->display_flags,DISPLAYf_NOT_RAW);
  Sleep(250);
  for(mm_phase=0;mm_phase<8;mm_phase++) {
    FlushMsgs;
    switch(mm_phase) {
      case 0:MsSet(160,160,0,FALSE,FALSE);break;
      case 1:MsSet(,,,TRUE,FALSE);break;
      case 2:MsSet(,,,FALSE,FALSE);break;
      case 3:MsSet(,,,FALSE,TRUE);break;
      case 4:MsSet(,,,FALSE,FALSE);break;
      case 5:MsSet;break;
      case 6:
        irq=GetRFlags;SetRFlags(irq&~0x200);MsSet(,,,TRUE,FALSE);MsSet(,,,FALSE,FALSE);
        if(GetRFlags&0x200)mm_good=FALSE;SetRFlags(irq);break;
      case 7:MsSet(176,184);break;
    }
    if(!(GetRFlags&0x200))mm_good=FALSE;
    Sleep(600);
    while(code=ScanMsg(&a,&b,0x1FF0)) {
      if(mm_count>=32)throw('SetMsgs',TRUE);
      r=mm_calls[mm_count++];r[0]=mm_phase;r[1]=code;r[2]=a;r[3]=b;
    }
    mm_rows[mm_phase][0]=mm_count;mm_rows[mm_phase][1]=ms.lb;mm_rows[mm_phase][2]=ms.rb;
    s=MStrPrint("MM READY %d\n",mm_phase);MMLog(s);Free(s);
    deadline=cnts.jiffies+20000;ch=0;
    while(ch!='n' && cnts.jiffies<deadline){ScanKey(&ch);Sleep(10);}
    if(ch!='n')throw('SetWait',TRUE);
  }
  Fs->put_doc=put;Fs->display_doc=display;DocDel(doc);Fs->win_inhibit=inhibit;
  WinBorder(bordered);WinHorz(left,right);WinVert(top,bottom);Fs->display_flags=flags;
  MsSet(old_x,old_y,old_z,old_lb,old_rb);
  if(TaskValidate(focus))WinFocus(focus);FlushMsgs;
  if(Fs->put_doc==put&&Fs->display_doc==display&&Fs->win_inhibit==inhibit)mm_mask|=1;
  if(Fs->data_heap->used_u8s==before)mm_mask|=2;
  if(mm_good)mm_mask|=4;
  s=MStrPrint("EXPORT set-message-rows.bin %X %X\n",mm_rows,sizeof(mm_rows));MMLog(s);Free(s);
  s=MStrPrint("EXPORT set-message-calls.bin %X %X\n",mm_calls,mm_count*32);MMLog(s);Free(s);
  s=MStrPrint("EXPORT set-message-mask.bin %X 8\n",&mm_mask);MMLog(s);Free(s);
  s=MStrPrint("EXPORT set-message-mode.bin %X 10\n",mm_mode);MMLog(s);Free(s);MMLog("MM DONE\n");
}
